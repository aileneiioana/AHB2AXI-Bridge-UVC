module ahb2axi_32bits (
  // AHB interface
  input               hclk,      // Clock						
  input               hresetn,   // HW reset, active low	
  // request
  input               hsel,      // Slave select						
  input         [1:0] htrans,    // Transfer type - IDLE, BUSY, SEQ, NONSEQ						
  input         [2:0] hburst,    // All except INCR (undefined length)						
  input         [2:0] hsize,     // Byte, Halfword, Word. Byte and Halfword is supported only if SINGLE						
  input        [31:0] haddr ,    // Addr. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)						
  input               hwrite,    // 0 - Read, 1 - Write						
  input        [31:0] hwdata,    // Write data						
  input         [3:0] hwstrobe,  // "Write strobe. For bursts is all ones. For SINGLE can be between 1 and 15. 
                                 // If hsize is not Word, make sure the bits set to 1 are matching the selected Bytes."
  // response 			
  output logic [31:0] hrdata,    // Read data						
  output logic        hreadyout, // Slave finished the transfer						
  output logic        hresp,     // Response: 0 - OKAY, 1 - ERROR						

  // AXI interface
  input               aclk,      // Clock						
  input               aresetn,   // HW reset, active low						
  // write address channel
  output logic        awvalid,   // Write request						
  output logic  [3:0] awid,      // Write ID. Between 0 and 15						
  output logic [31:0] awaddr,    // Write address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)						
  output logic  [3:0] awlen,     // Burst length (no of cycles in burst - 1)						
  output logic  [2:0] awsize,	 // Byte, Halfword, Word. Byte and Halfword is supported only if burst length is 1.						
  output logic  [1:0] awburst,	 // Burst type: FIXED, INCR, WRAP						
  input               awready,	 // Write request acknowledge						
  // write data channel
  output logic        wvalid,    // Write data valid						
  output logic [31:0] wdata,     // Write data						
  output logic  [3:0] wstrb,     // Write strobe. For bursts (more than 1 cycle) is all ones. For bursts of 1 cycle, it can be between 1 and 15.  If size is not Word, make sure the bits set to 1 are matching the selected Bytes.						
  output logic        wlast,     // Write data last						
  input               wready,    // Write data ready						
  // write response channel
  input               bvalid,    // Write response valid						
  input         [3:0] bid,       // Write response ID.						
  output logic        bready,    // Write response ready - stuck to 1						
  // read address channel
  output logic        arvalid,   // Read request						
  output logic  [3:0] arid,      // Read ID. Between 0 and 15						
  output logic [31:0] araddr,    // Read address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)						
  output logic  [3:0] arlen,     // Burst length (no of cycles in burst - 1)						
  output logic  [2:0] arsize,    // Byte, Halfword, Word. Byte and Halfword is supported only if burst length is 1.						
  output logic  [1:0] arburst,   // Burst type: FIXED, INCR, WRAP						
  input               arready,   // Read request acknowledge						
  // read data channel
  input               rvalid,    // Read data valid						
  input        [31:0] rdata,     // Read data						
  input               rlast,     // Read data last						
  input         [3:0] rid,       // Read response ID.						
  input         [1:0] rresp,     // Read response status: all posibilities supported						
  output logic        rready     // Read data ready	- stuck to 1				
);

localparam CTRL_REG_ADDR = 32'h0000_0100;
localparam CTRL_REG_MASK = 32'h0000_3F03;

localparam WR_DATA_QUEUE_MAX_SIZE = 32*16; // max 32 requests with 16 cycles each

/*********************************************************************************/
// enums for various fields of AHB transfer
enum bit [1:0] {
  AHB_IDLE   = 2'b00,
  AHB_BUSY   = 2'b01,
  AHB_NONSEQ = 2'b10,
  AHB_SEQ    = 2'b11
} htrans_e;

enum bit [2:0] {
  AHB_SINGLE = 3'b000,
  AHB_WRAP4  = 3'b010,
  AHB_INCR4  = 3'b011,
  AHB_WRAP8  = 3'b100,
  AHB_INCR8  = 3'b101,
  AHB_WRAP16 = 3'b110,
  AHB_INCR16 = 3'b111  
} hburst_e;

enum bit [2:0] {
  AHB_BYTE     = 3'b000,
  AHB_HALFWORD = 3'b001,
  AHB_WORD     = 3'b010
} hsize_e;

enum  bit {
  AHB_WRITE = 1'b1,
  AHB_READ  = 1'b0
} hwrite_e;

enum  bit {
  AHB_OKAY   = 1'b0,
  AHB_ERROR  = 1'b1
} hresp_e;

/*********************************************************************************/
// enums for various fields of AXI transfer
enum  bit [2:0] {
  AXI_BYTE     = 3'b000,
  AXI_HALFWORD = 3'b001,
  AXI_WORD     = 3'b010
} axsize_e;

enum bit [1:0] {
  AXI_FIXED = 2'b00,
  AXI_INCR  = 2'b01,
  AXI_WRAP  = 2'b10
} axurst_e;

enum  bit [1:0] {
  AXI_OKAY     = 2'b00,
  AXI_EXOKAY   = 2'b01,
  AXI_SLVERR   = 2'b10,
  AXI_DECERR   = 2'b11  
} axresp_e;
/*********************************************************************************/

// stuck signals
assign bready = 1'b1;
assign rready = 1'b1;

/*********************************************************************************/
/// AHB side
/*********************************************************************************/
logic ahb_addr_phase;
logic ahb_data_phase;
logic [31:0] ahb_haddr_s;
logic  [2:0] ahb_hsize_s;
logic        ahb_hwrite_s;
logic ctrl_space_access;
logic axi_space_addr_phase;
logic axi_space_data_phase;
logic [31:0] ctrl_reg;

// address phase
assign ahb_addr_phase = hsel & hreadyout & ((htrans == AHB_NONSEQ) | (htrans == AHB_SEQ));

// data phase - set at address phase, reset at hreadyout
// sample the address, size and write from the address phase
initial begin
  ahb_haddr_s <= 0;
  ahb_hsize_s <= 0;
  ahb_hwrite_s <= 0;
  forever begin
    @(posedge hclk iff ahb_addr_phase);
    ahb_haddr_s <= haddr;
    ahb_hsize_s <= hsize;
    ahb_hwrite_s <= hwrite;
  end
end

initial begin
  ahb_data_phase <= 0;
  forever begin
    @(posedge hclk iff ahb_addr_phase);
    ahb_data_phase <= 1;
    @(posedge hclk iff (hreadyout & ~ahb_addr_phase));
    ahb_data_phase <= 0;  
  end
end

// control address space access
assign ctrl_space_access = ahb_data_phase & (ahb_haddr_s < 32'h1000_0000);

// axi address space access
assign axi_space_addr_phase = hsel & hreadyout & (htrans == AHB_NONSEQ) & (haddr >= 32'h1000_0000);
assign axi_space_data_phase = ahb_data_phase & (ahb_haddr_s >= 32'h1000_0000);

// Control register
initial begin
  @(posedge hresetn);
  ctrl_reg <= 0;
  forever begin
    // write to the register, support for sub-size access
	@(posedge hclk iff (ctrl_space_access & (ahb_haddr_s >= CTRL_REG_ADDR) & (ahb_haddr_s < CTRL_REG_ADDR + 4) & ahb_hwrite_s)); 
	case (ahb_hsize_s)
	  AHB_BYTE     : if (ahb_haddr_s[1:0] == 0) ctrl_reg[7:0] <= hwdata[7:0] & {8{hwstrobe[0]}} & CTRL_REG_MASK[7:0];
	                 else if (ahb_haddr_s[1:0] == 1) ctrl_reg[15:8] <= hwdata[15:8] & {8{hwstrobe[1]}} & CTRL_REG_MASK[15:8];
	  AHB_HALFWORD : if (ahb_haddr_s[1:0] == 0) ctrl_reg[15:0] <= hwdata[15:0] & {{8{hwstrobe[1]}}, {8{hwstrobe[0]}}} & CTRL_REG_MASK[15:0]; 
	  AHB_WORD     : ctrl_reg <= hwdata & {{8{hwstrobe[3]}}, {8{hwstrobe[2]}}, {8{hwstrobe[1]}}, {8{hwstrobe[0]}}} & CTRL_REG_MASK; 
	  default      : begin 
	                   $display("Received an unexpected AHB hsize %0d",ahb_hsize_s);
					   $stop();
					 end
	endcase
  end
end

// push the current request into the pending requests queues
bit [37:0] wr_pend_req_q [$]; // it stores {hburst, hsize, haddr}
bit [37:0] rd_pend_req_q [$]; // it stores {hburst, hsize, haddr}

initial begin
  forever begin
    @(posedge hclk iff (axi_space_addr_phase & hwrite));
	wr_pend_req_q.push_back({hburst, hsize, haddr});
	//$display("Push into write requests queue at %0t",$time);
  end
end

initial begin
  forever begin
    @(posedge hclk iff (axi_space_addr_phase & ~hwrite));
	rd_pend_req_q.push_back({hburst, hsize, haddr});
	//$display("Push into read requests queue at %0t",$time);
  end
end

// in case this is a write to AXI space, push the data into the pending data queues
bit [35:0] wr_pend_data_q [$]; // it stores {hwdata, hwstrobe}

initial begin
  forever begin
    @(posedge hclk iff (axi_space_data_phase & hreadyout & ahb_hwrite_s));
	wr_pend_data_q.push_back({hwstrobe, hwdata});
	//$display("Push into write data queue at %0t",$time);	
  end
end

// in case of reads from AXI, data to be put on hrdata and the error indication are taken from the axi_rd_data_q
bit  [2:0] axi_rresp;
bit [31:0] axi_rdata;
bit  [2:0] axi_rresp_nxt;
bit [31:0] axi_rdata_nxt;
bit [34:0] axi_rd_data_q[$];
bit        axi_rdata_available;
bit [4:0]  rd_cycles;
int index;

initial begin
  rd_cycles = 0;
  forever begin
    @(posedge hclk iff (axi_space_addr_phase & ~hwrite));
	case (hburst)
	  AHB_SINGLE : rd_cycles = 1;
	  AHB_WRAP4  : rd_cycles = 4;
	  AHB_INCR4  : rd_cycles = 4;
	  AHB_WRAP8  : rd_cycles = 8;
	  AHB_INCR8  : rd_cycles = 8;
	  AHB_WRAP16 : rd_cycles = 16;
	  AHB_INCR16 : rd_cycles = 16;
	endcase
  end
end

initial begin
  axi_rdata_available <= 0;
  forever begin  
    @(posedge hclk iff (axi_space_data_phase & !ahb_hwrite_s & (axi_rd_data_q.size() == rd_cycles)));
    axi_rdata_available <= 1;
    {axi_rresp, axi_rdata} <= axi_rd_data_q.pop_front(); // get data from the queue
    {axi_rresp_nxt,axi_rdata_nxt} <= axi_rd_data_q[0];
    for (int i = 0; i < (rd_cycles -1); i++) begin
      @(posedge hclk iff (hreadyout & (htrans == AHB_SEQ))); // wait for hreadyout to be set
      {axi_rresp, axi_rdata} <= axi_rd_data_q.pop_front(); // get data from the queue
      if (axi_rd_data_q.size() > 0) begin
         {axi_rresp_nxt,axi_rdata_nxt} <= axi_rd_data_q[0];
      end
    end
    @(posedge hclk iff hreadyout);
    axi_rdata_available <= 0;
    axi_rresp_nxt <= 0;
  end
end

// response is always OKAY, except when doing reads from AXI and error response comes back
assign hresp = (axi_space_data_phase & ~ahb_hwrite_s & axi_rdata_available & ((axi_rresp == AXI_SLVERR) | (axi_rresp == AXI_DECERR))) ? AHB_ERROR : AHB_OKAY;

// read data, from control address space or from AXI
assign hrdata = (ahb_data_phase & (ahb_haddr_s >= CTRL_REG_ADDR) & (ahb_haddr_s < CTRL_REG_ADDR + 4)) ? ctrl_reg : 
                (axi_space_data_phase & ~ahb_hwrite_s & axi_rdata_available)                          ? axi_rdata :
                                                                                                        0;

// hreadyout
initial begin
  hreadyout <= 1;
  forever begin
    @(posedge hclk);
	if (axi_space_addr_phase & ~hwrite) begin// AXI read - NONSEQ cycle
	  hreadyout <= 0;
	  end
    else if (~ahb_hwrite_s & axi_rdata_available & hreadyout & (htrans == AHB_SEQ) & ((axi_rresp_nxt == AXI_SLVERR) | (axi_rresp_nxt == AXI_DECERR))) begin // error response has 2 cycles
	  hreadyout <= 0;
      @(posedge hclk);
	  hreadyout <= 1;
      //@(posedge hclk);	  
	end
	else if (~axi_space_data_phase)
	  hreadyout <= 1;
    else if (axi_space_data_phase & ahb_hwrite_s & (wr_pend_data_q.size() == (WR_DATA_QUEUE_MAX_SIZE - 1))) // when writing to the queue last location
	  hreadyout <= 0;
	else if (~hreadyout & axi_space_data_phase & ahb_hwrite_s & (wr_pend_data_q.size() < WR_DATA_QUEUE_MAX_SIZE )) // if write data queue was full, and one spot is now available
	  hreadyout <= 1;
	else if (axi_space_data_phase & ~ahb_hwrite_s & axi_rdata_available)  
	  hreadyout <= 1;
	else if (axi_space_data_phase & ~ahb_hwrite_s & ~axi_rdata_available)  
	  hreadyout <= 0;	  
  end
end
  
/*********************************************************************************/
/// AXI read side
/*********************************************************************************/

logic  [2:0] rd_hburst; 
logic  [2:0] rd_hsize;  
logic [31:0] rd_haddr ; 

logic [5:0] rd_ahb_length;
logic [4:0] rd_axi_length;
logic       rd_ahb_over_4k;
logic       rd_wrap_to_incr;
logic [3:0] rd_wrap_offset; // wrap burst start address offset from aligned address

bit  [9:0] axi_rd_req_info_q[$];
bit  [4:0] axi_rd_cycles;
bit        axi_rd_wrap_to_incr;
bit  [3:0] axi_rd_wrap_offset;

int rd_wrap_index;

bit [34:0] rd_incr_data_array[16];

bit [5:0] rand_time_btwn_rvalids;

// get request from AHB requests queue, and put them on the AXI bus
initial begin
  arvalid <= 0;

  // wait for reset
  @(posedge aresetn);

  forever begin
    @(posedge aclk iff (rd_pend_req_q.size() > 0));
    {rd_hburst, rd_hsize, rd_haddr} = rd_pend_req_q.pop_front();
     rd_ahb_length = (rd_hburst == AHB_SINGLE) ? 1 :
                     ((rd_hburst == AHB_WRAP4) | (rd_hburst == AHB_INCR4)) ? 4 :
                     ((rd_hburst == AHB_WRAP8) | (rd_hburst == AHB_INCR8)) ? 8 :
                                                                             16;

     rd_ahb_over_4k = ((rd_hburst == AHB_INCR4) | (rd_hburst == AHB_INCR8) | (rd_hburst == AHB_INCR16)) & 
                      ((rd_haddr[11:0] + rd_ahb_length*4) > 4096);

    // AHB issues a wrap, but AXI does not support WRAP, convert this to INCR
    rd_wrap_to_incr = ((rd_hburst == AHB_WRAP4) | (rd_hburst == AHB_WRAP8) | (rd_hburst == AHB_WRAP16)) & ~ctrl_reg[1];

    // wrap burst start address offset from aligned address
    rd_wrap_offset = (rd_wrap_to_incr & (rd_hburst == AHB_WRAP4))  ? (rd_haddr[3:0] / 4) :
                     (rd_wrap_to_incr & (rd_hburst == AHB_WRAP8))  ? (rd_haddr[4:0] / 4) :
                     (rd_wrap_to_incr & (rd_hburst == AHB_WRAP16)) ? (rd_haddr[5:0] / 4) :
                                                                      0;

    arsize <= (rd_hsize == AHB_BYTE) ? AXI_BYTE :
              (rd_hsize == AHB_HALFWORD) ? AXI_HALFWORD : AXI_WORD;
    arburst <= (rd_hburst == AHB_SINGLE)                                                                         ? AXI_FIXED :
               (((rd_hburst == AHB_WRAP4) | (rd_hburst == AHB_WRAP8) | (rd_hburst == AHB_WRAP16)) & ctrl_reg[1]) ? AXI_WRAP   :
                                                                                                                   AXI_INCR;
    arvalid <= 1;
    arid    <= $urandom_range(0,15);
    
    // address part
    if (rd_wrap_to_incr) araddr <= (rd_hburst == AHB_WRAP4) ? {rd_haddr[31:4],4'd0} :
                                   (rd_hburst == AHB_WRAP8) ? {rd_haddr[31:5],5'd0} :
                                                              {rd_haddr[31:6],6'd0};
    else                 araddr <= rd_haddr;      
     
    // length part
    if (rd_ahb_over_4k) arlen <= ((4096 - rd_haddr[11:0]) / 4) - 1; // in case of 4K, the length of the first transfer is changed to reach the 4K but not exceed it
    else                arlen <= rd_ahb_length - 1;

    @(posedge aclk iff arready); // wait for awready to be received

    rd_axi_length = (arlen + 1'b1);

    axi_rd_req_info_q.push_back({rd_wrap_offset, rd_wrap_to_incr, rd_axi_length});
    
    arvalid <= 0; // last request cycle, reset valid

    if (rd_ahb_over_4k) begin
      @(posedge aclk iff (rvalid & rlast & rready)); // a new request can be sent out
      arvalid <= 1;
      arid    <= $urandom_range(0,15);
      araddr  <= {rd_haddr[31:12],12'd0}+{1'b1,12'd0}; // start from next 4K
      arlen   <= ((rd_haddr[11:0] + rd_ahb_length*4) - 4096) / 4 - 1; // use remaining burst cycles  

      rd_axi_length = ((rd_haddr[11:0] + rd_ahb_length*4) - 4096) / 4;
      axi_rd_req_info_q.push_back({3'd0, 1'b0 , rd_axi_length});
    end
    
    @(posedge aclk iff arready); // wait for awready to be received
    
    arvalid <= 0; // last request cycle, reset valid   
  end  

end

// re-order in case of wrap to incr conversion, push response error and data into queue
// they will be used on the AHB side
initial begin
  // wait for reset
  @(posedge aresetn);

  forever begin
    @(posedge aclk iff (arvalid & arready));

    @(posedge aclk);

    {axi_rd_wrap_offset, axi_rd_wrap_to_incr, axi_rd_cycles} = axi_rd_req_info_q.pop_front();

    rd_wrap_index = 0;

    for (int i = 0; i < axi_rd_cycles; i ++) begin

      @(posedge aclk iff rvalid);

      if (axi_rd_wrap_to_incr) begin
        rd_incr_data_array[rd_wrap_index] = {rresp, rdata};
        rd_wrap_index++;
        if (rlast) begin
          // put data in order, starting from aligned address
          for (int k =  axi_rd_wrap_offset; k < axi_rd_cycles ; k++) begin
            axi_rd_data_q.push_back(rd_incr_data_array[k]);
          end
          for (int k = 0; k < axi_rd_wrap_offset; k++) begin
            axi_rd_data_q.push_back(rd_incr_data_array[k]);
          end
        end
      end else begin
	    axi_rd_data_q.push_back({rresp, rdata});
      end 
    end
  end
end

/*********************************************************************************/
/// AXI write side
/*********************************************************************************/

logic [5:0] pend_wr_cnt; // number of pending transfers on write side

logic  [2:0] wr_hburst; 
logic  [2:0] wr_hsize;  
logic [31:0] wr_haddr ; 

logic [5:0] wr_ahb_length;
logic [4:0] wr_axi_length;
logic       wr_ahb_over_4k;
logic       wr_wrap_to_incr;
logic [3:0] wr_wrap_offset; // wrap burst start address offset from aligned address

bit  [9:0] axi_wr_req_info_q[$];
bit  [4:0] axi_wr_cycles;
bit        axi_wr_wrap_to_incr;
bit  [3:0] axi_wr_wrap_offset;

int wr_wrap_index;

bit [35:0] wr_wrap_data_array [16];
bit [31:0] wr_incr_data_array [16];

initial begin
  pend_wr_cnt <= 0;
  // wait for reset
  @(posedge aresetn);

  // increment at req, decrement at bvalid
  forever begin
    @(posedge aclk);
    pend_wr_cnt <= pend_wr_cnt + (awvalid & awready) - bvalid;
  end
end

// get request from AHB requests queue, and put them on the AXI bus
initial begin
  awvalid <= 0;

  // wait for reset
  @(posedge aresetn);

  forever begin
    @(posedge aclk iff ((wr_pend_req_q.size() > 0) & ((~ctrl_reg[0] & (pend_wr_cnt == 0)) | (pend_wr_cnt < ctrl_reg[13:8]))));
    {wr_hburst, wr_hsize, wr_haddr} = wr_pend_req_q.pop_front();
     wr_ahb_length = (wr_hburst == AHB_SINGLE) ? 1 :
                     ((wr_hburst == AHB_WRAP4) | (wr_hburst == AHB_INCR4)) ? 4 :
                     ((wr_hburst == AHB_WRAP8) | (wr_hburst == AHB_INCR8)) ? 8 :
                                                                             16;

     wr_ahb_over_4k = ((wr_hburst == AHB_INCR4) | (wr_hburst == AHB_INCR8) | (wr_hburst == AHB_INCR16)) & 
                      ((wr_haddr[11:0] + wr_ahb_length*4) > 4096);

    // AHB issues a wrap, but AXI does not support WRAP, convert this to INCR
    wr_wrap_to_incr = ((wr_hburst == AHB_WRAP4) | (wr_hburst == AHB_WRAP8) | (wr_hburst == AHB_WRAP16)) & ~ctrl_reg[1];

    // wrap burst start address offset from aligned address
    wr_wrap_offset = (wr_wrap_to_incr & (wr_hburst == AHB_WRAP4))  ? (wr_haddr[3:0] / 4) :
                     (wr_wrap_to_incr & (wr_hburst == AHB_WRAP8))  ? (wr_haddr[4:0] / 4) :
                     (wr_wrap_to_incr & (wr_hburst == AHB_WRAP16)) ? (wr_haddr[5:0] / 4) :
                                                                     0;

    awsize <= (wr_hsize == AHB_BYTE) ? AXI_BYTE :
              (wr_hsize == AHB_HALFWORD) ? AXI_HALFWORD : AXI_WORD;
    awburst <= (wr_hburst == AHB_SINGLE)                                                                         ? AXI_FIXED :
               (((wr_hburst == AHB_WRAP4) | (wr_hburst == AHB_WRAP8) | (wr_hburst == AHB_WRAP16)) & ctrl_reg[1]) ? AXI_WRAP   :
                                                                                                                   AXI_INCR;
    awvalid <= 1;
    awid    <= $urandom_range(0,15);
    
    // address part
    if (wr_wrap_to_incr) awaddr <= (wr_hburst == AHB_WRAP4) ? {wr_haddr[31:4],4'd0} :
                                   (wr_hburst == AHB_WRAP8) ? {wr_haddr[31:5],5'd0} :
                                                              {wr_haddr[31:6],6'd0};
    else                 awaddr <= wr_haddr;      
     
    // length part
    if (wr_ahb_over_4k) awlen <= ((4096 - wr_haddr[11:0]) / 4) - 1; // in case of 4K, the length of the first transfer is changed to reach the 4K but not exceed it
    else                awlen <= wr_ahb_length - 1;

    @(posedge aclk iff awready); // wait for awready to be received

    wr_axi_length = (awlen + 1'b1);

    axi_wr_req_info_q.push_back({wr_wrap_offset, wr_wrap_to_incr, wr_axi_length});
    
    awvalid <= 0; // last request cycle, reset valid

    if (wr_ahb_over_4k) begin
      @(posedge aclk iff ((~ctrl_reg[0] & (pend_wr_cnt == 0)) | (pend_wr_cnt < ctrl_reg[13:8]))); // a new request can be sent out
      awvalid <= 1;
      awid    <= $urandom_range(0,15);
      awaddr  <= {wr_haddr[31:12],12'd0}+{1'b1,12'd0}; // start from next 4K
      awlen   <= ((wr_haddr[11:0] + wr_ahb_length*4) - 4096) / 4 - 1; // use remaining burst cycles  

      wr_axi_length = ((wr_haddr[11:0] + wr_ahb_length*4) - 4096) / 4;
      axi_wr_req_info_q.push_back({3'd0, 1'b0 , wr_axi_length});
    end
    
    @(posedge aclk iff awready); // wait for awready to be received
    
    awvalid <= 0; // last request cycle, reset valid   
  end  

end

// prepare write data and put it on the AXI bus
initial begin
  wvalid <= 0;
  wdata  <= 0;
  wstrb  <= 'hF;
  wlast  <= 0;
  // wait for reset
  @(posedge aresetn);

  forever begin
    @(posedge aclk iff (axi_wr_req_info_q.size() != 0));
    {axi_wr_wrap_offset, axi_wr_wrap_to_incr, axi_wr_cycles} = axi_wr_req_info_q.pop_front();

    wr_wrap_index = 0;
     
    // in case WRAP is not supported on AXI, and the request was with WRAP need to wait for all AHB data to be available
    if (axi_wr_wrap_to_incr) begin
      @(posedge aclk iff (wr_pend_data_q.size() >= axi_wr_cycles));
      for (int j = 0; j < axi_wr_cycles; j++) // get data from the queue
        wr_wrap_data_array[j] = wr_pend_data_q.pop_front();
      // put data in order, starting from aligned address
      for (int k = (axi_wr_cycles - axi_wr_wrap_offset); k < axi_wr_cycles ; k++) begin
        wr_incr_data_array [wr_wrap_index] = wr_wrap_data_array[k][31:0];
        wr_wrap_index++;
      end
      for (int k = 0; k < (axi_wr_cycles - axi_wr_wrap_offset); k++) begin
        wr_incr_data_array [wr_wrap_index] = wr_wrap_data_array[k][31:0];
        wr_wrap_index++;
      end
     
      // drive all beats of data on the bus
      for (int j = 0; j < axi_wr_cycles; j++) begin
        wvalid <= 1;
        wdata  <= wr_incr_data_array[j];
        wstrb  <= 'hF;
        wlast  <= (j == (axi_wr_cycles - 1));
        @(posedge aclk iff wready);
      end

      wvalid <= 0;
      wlast  <= 0;
    end else begin // not wrap, send data out as it received from AHB
      @(posedge aclk iff (wr_pend_data_q.size() >= axi_wr_cycles));
      // drive all beats of data on the bus
      for (int j = 0; j < axi_wr_cycles; j++) begin
        wvalid <= 1;
        {wstrb, wdata}  <= wr_pend_data_q.pop_front();
        wlast  <= (j == (axi_wr_cycles - 1)) | (axi_wr_cycles == 1);
        @(posedge aclk iff wready);
      end 
      wvalid <= 0;
      wlast  <= 0;    
    end
  end  

end				

endmodule