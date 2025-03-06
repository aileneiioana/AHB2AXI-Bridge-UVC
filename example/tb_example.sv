`timescale 1ns/1ps

`include "ahb_if.sv"
`include "ahb_pkg.sv"
`include "axi_if.sv"
`include "axi_pkg.sv"
`include "../rtl/ahb2axi_32bits.sv"

module tb_example();

   import uvm_pkg::*;
   `include "uvm_macros.svh"
   import ahb_pkg::*;
   import axi_pkg::*;
   `include "test_lib.sv"
   
   // WRITE ADDRESS CHANNEL
   wire        awvalid ; // Write request
   wire [ 3:0] awid    ; // Write ID. Between 0 and 15
   wire [31:0] awaddr  ; // Write address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)
   wire [ 3:0] awlen   ; // Burst length (no of cycles in burst - 1)
   wire [ 2:0] awsize  ; // Byte, Halfword, Word. Byte and Halfword is supported only if burst length is 1.
   wire [ 1:0] awburst ; // Burst type: FIXED, INCR, WRAP
   wire        awready ; // Write request acknowledge
   wire        awlock  ; // Write lock type. Provides additional information about the atomic characteristics of the transfer.
   wire [ 3:0] awcache ; // Write Cache type. This signal indicates how transactions are required to progress through a system.
   wire [ 2:0] awprot  ; // Write Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access.
     
   // WRITE DATA CHANNEL
   wire        wvalid  ; // Write data valid
   wire [31:0] wdata   ; // Write data
   wire [ 3:0] wstrb   ; // Write strobe. For bursts (more than 1 cycle) is all ones. 
                         // For bursts of 1 cycle, it can be between 1 and 15.  
                         // If size is not Word, make sure the bits set to 1 are matching the selected Bytes.
   wire        wlast   ; // Write data last
   wire        wready  ; // Write data ready
   
   // WRITE RESPONSE CHANNEL
   wire        bvalid  ; // Write response valid
   wire [ 3:0] bid     ; // Write response ID.
   wire        bready  ; // Write response ready - stuck to 1
   wire[  1:0] bresp   ; // Write Response
   
   // READ ADDRESS CHANNEL
   wire        arvalid ; // Read request
   wire [ 3:0] arid    ; // Read ID. Between 0 and 15
   wire [31:0] araddr  ; // Read address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)
   wire [ 3:0] arlen   ; // Burst length (no of cycles in burst - 1)
   wire [ 2:0] arsize  ; // Byte, Halfword, Word. Byte and Halfword is supported only if burst length is 1.
   wire [ 1:0] arburst ; // Burst type: FIXED, INCR, WRAP
   wire        arready ; // Read request acknowledge
   wire        arlock  ; // Read lock type. This signal provides additional information about the atomic characteristics of the transfer.
   wire [ 3:0] arcache ; // Read Cache type. This signal indicates how transactions are required to progress through a system.
   wire [ 2:0] arprot  ; // Read Protection type. This signal indicates the privilege and security level of the transaction, and whether the transaction is a data access or an instruction access
   
   // READ DATA CHANNEL
   wire        rvalid  ; // Read data valid
   wire [31:0] rdata   ; // Read data
   wire [ 3:0] rid     ; // Read data last
   wire        rlast   ; // Read response ID.
   wire [ 1:0] rresp   ; // Read response status: all posibilities supported
   wire        rready  ; // Read data ready.
   
   
   reg         aclk    ;
   reg         aresetn ;
   
   // Master wires
   wire        hsel     ; //slave select 
   wire        hwrite   ; //write/read selector
   wire [ 1:0] htrans   ; //transfer type - IDLE, BUSY, SEQ, NONSEQ
   wire [ 2:0] hburst   ;
   wire [ 2:0] hsize    ; //Byte, Halfword, Word
   wire [31:0] haddr    ; //registers address
   wire [31:0] hwdata   ; //data from Master
   wire [ 3:0] hwstrobe ; //Write strobe. For bursts is all ones. For SINGLE can be between 1 and 15. If hsize is not Word, make sure the bits set to 1 are matching the selected Bytes.
   
  // Slave wires 
   wire [31:0] hrdata   ; //data from Slave
   wire        hreadyout; //Slave finished the transfer
   wire        hresp    ;    //Slave response 0-OKAY, 1-ERROR
   
   reg         hclk     ;
   reg         hreset_n ;
   
   initial begin
      aclk = 0;
      #100ns;
      aresetn = 1'b0;
      #100ns;
      aresetn = 1'b1;
        
   end
   
   initial forever #0.83ns aclk =! aclk;
   
      initial begin
      hclk = 0;
      #100ns;
      hreset_n = 1'b0;
      #100ns;
      hreset_n = 1'b1;
        
   end
   
   initial forever #0.83ns hclk =! hclk;
   
   // Interface instances
   ahb_if#(32,32) ahb_master_if (hclk, hreset_n);       
     /*assign hsel     = ahb_master_if.hsel      ;
      assign hwrite   = ahb_master_if.hwrite    ;
      assign htrans   = ahb_master_if.htrans    ;
      assign hburst   = ahb_master_if.hburst    ;
      assign hsize    = ahb_master_if.hsize     ;
      assign haddr    = ahb_master_if.haddr     ;
      assign hwdata   = ahb_master_if.hwdata    ;
      assign hwstrobe = ahb_master_if.hwstrobe  ;
      
      assign ahb_master_if.hrdata    = hrdata   ;
      assign ahb_master_if.hreadyout = hreadyout;
      assign ahb_master_if.hresp     = hresp    ;*/
   
  axi_if#(32,32) axi_slave_if (aclk, aresetn) ;       
      /*assign axi_slave_if.awvalid = awvalid;
      assign axi_slave_if.awid    = awid;
      assign axi_slave_if.awaddr  = awaddr;
      assign axi_slave_if.awlen   = awlen;
      assign axi_slave_if.awsize  = awsize;
      assign axi_slave_if.awburst = awburst;
      assign axi_slave_if.wvalid  = wvalid;
      assign axi_slave_if.wdata   = wdata;
      assign axi_slave_if.wstrb   = wstrb;
      assign axi_slave_if.wlast   = wlast;
      assign axi_slave_if.bready  = bready;
      assign axi_slave_if.arvalid = arvalid;
      assign axi_slave_if.arid    = arid;
      assign axi_slave_if.araddr  = araddr;
      assign axi_slave_if.arlen   = arlen;
      assign axi_slave_if.arsize  = arsize;
      assign axi_slave_if.arburst = arburst;
      assign axi_slave_if.rready  = rready;
      assign axi_slave_if.awcache = awcache;
      assign axi_slave_if.awprot  = awprot;
      assign axi_slave_if.awlock  = awlock;
      assign axi_slave_if.arcache = arcache;
      assign axi_slave_if.arprot  = arprot;
      assign axi_slave_if.arlock  = arlock;
      
      assign awready = axi_slave_if.awready;
      assign wready  = axi_slave_if.wready;
      assign bvalid  = axi_slave_if.bvalid;
      assign bid     = axi_slave_if.bid;
      assign bresp   = axi_slave_if.bresp;
      assign arready = axi_slave_if.arready;
      assign rvalid  = axi_slave_if.rvalid;
      assign rdata   = axi_slave_if.rdata;
      assign rlast   = axi_slave_if.rlast;
      assign rid     = axi_slave_if.rid;
      assign rresp   = axi_slave_if.rresp;*/

      //DUT
 ahb2axi_32bits ahb2axi_32bits_i(
      .hclk      (ahb_master_if.hclk),
      .hresetn   (ahb_master_if.hreset_n),
      .hsel      (ahb_master_if.hsel),
      .htrans    (ahb_master_if.htrans),
      .hburst    (ahb_master_if.hburst),  
      .hsize     (ahb_master_if.hsize),
      .haddr     (ahb_master_if.haddr),      
      .hwrite    (ahb_master_if.hwrite),
      .hwdata    (ahb_master_if.hwdata),      
      .hwstrobe  (ahb_master_if.hwstrobe),    
      .hrdata    (ahb_master_if.hrdata),
      .hreadyout (ahb_master_if.hreadyout),         
      .hresp     (ahb_master_if.hresp),  
 
      .aclk      (axi_slave_if.aclk),         
      .aresetn   (axi_slave_if.aresetn),
      .awvalid   (axi_slave_if.awvalid),
      .awid      (axi_slave_if.awid),
      .awaddr   (axi_slave_if.awaddr),
      .awlen     (axi_slave_if.awlen),
      .awsize    (axi_slave_if.awsize),
      .awburst   (axi_slave_if.awburst),
      .wvalid    (axi_slave_if.wvalid),
      .wdata     (axi_slave_if.wdata),
      .wstrb     (axi_slave_if.wstrb),
      .wlast     (axi_slave_if.wlast),
      .bready    (axi_slave_if.bready),
      .arvalid   (axi_slave_if.arvalid),
      .arid      (axi_slave_if.arid),
      .araddr    (axi_slave_if.araddr),
      .arlen     (axi_slave_if.arlen),
      .arsize    (axi_slave_if.arsize),
      .arburst   (axi_slave_if.arburst),
      .rready    (axi_slave_if.rready),
      .awready   (axi_slave_if.awready),
      .wready    (axi_slave_if.wready),
      .bvalid    (axi_slave_if.bvalid),
      .bid       (axi_slave_if.bid),
      .arready   (axi_slave_if.arready),
      .rvalid    (axi_slave_if.rvalid),
      .rdata     (axi_slave_if.rdata),
      .rlast     (axi_slave_if.rlast),
      .rid       (axi_slave_if.rid),
      .rresp     (axi_slave_if.rresp)
);
/*
ahb2axi_32bits ahb2axi_32bits_i(
      .hclk      (hclk),
      .hresetn   (hresetn),
      .hsel      (hsel),
      .htrans    (htrans),
      .hburst    (hburst),  
      .hsize     (hsize),
      .haddr     (haddr),      
      .hwrite    (hwrite),
      .hwdata    (hwdata),      
      .hwstrobe  (hwstrobe),    
      .hrdata    (hrdata),
      .hreadyout (hreadyout),         
      .hresp     (hresp),  
 
      .aclk      (aclk),         
      .aresetn   (aresetn),
      .awvalid   (awvalid),
      .awid      (awid),
      .awaddr    (awaddr),
      .awlen     (awlen),
      .awsize    (awsize),
      .awburst   (awburst),
      .wvalid    (wvalid),
      .wdata     (wdata),
      .wstrb     (wstrb),
      .wlast     (wlast),
      .bready    (bready),
      .arvalid   (arvalid),
      .arid      (arid),
      .araddr    (araddr),
      .arlen     (arlen),
      .arsize    (arsize),
      .arburst   (arburst),
      .rready    (rready),
      .awready   (awready),
      .wready    (wready),
      .bvalid    (bvalid),
      .bid       (bid),
      .arready   (arready),
      .rvalid    (rvalid),
      .rdata     (rdata),
      .rlast     (rlast),
      .rid       (rid),
      .rresp     (rresp)
);
*/
   initial begin
      // Setting AHB MASTER interface
      uvm_config_db #(virtual interface ahb_if#(32,32))::set(null,"*.master_env.*","ahb_vif",ahb_master_if);
      // Setting AXI SLAVE interface
      uvm_config_db #(virtual interface axi_if#(32,32))::set(null,"*.slave_env.*","axi_vif",axi_slave_if);
      // Start UVM components
      run_test();
   end   

endmodule
