`timescale 1ns/1ps

`include "axi_if.sv"
`include "axi_pkg.sv"

module tb_example();

   import uvm_pkg::*;
   `include "uvm_macros.svh"
   
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
   
   // READ ADDRESS CHANNEL
   wire        arvalid ; // Read request
   wire [ 3:0] arid    ; // Read ID. Between 0 and 15
   wire [31:0] araddr  ; // Read address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)
   wire [ 3:0] arlen   ; // Burst length (no of cycles in burst - 1)
   wire [ 2:0] arsize  ; // Byte, Halfword, Word. Byte and Halfword is supported only if burst length is 1.
   wire [ 1:0] arburst ; // Burst type: FIXED, INCR, WRAP
   wire        arready ; // Read request acknowledge
   
   // READ DATA CHANNEL
   wire        rvalid  ; // Read data valid
   wire [31:0] rdata   ; // Read data
   wire [ 3:0] rid     ; // Read data last
   wire        rlast   ; // Read response ID.
   wire [ 1:0] rresp   ; // Read response status: all posibilities supported
   wire        rready  ; // Read data ready.
   
   
   reg         aclk    ;
   reg         aresetn ;
   
   initial begin
      aclk = 0;
      aresetn = 1'b1;
      #100ns;
      aresetn = 1'b0;
      #100ns;
      aresetn = 1'b1;
   end
   
   initial forever #0.83ns aclk =! aclk;
   
   // Interface instances
   axi_if#(32,32) axi_master_if (aclk, aresetn);  
      // WRITE ADDRESS CHANNEL
      assign awvalid = axi_master_if.awvalid ;
      assign awid    = axi_master_if.awid    ;
      assign awaddr  = axi_master_if.awaddr  ;
      assign awlen   = axi_master_if.awlen   ;
      assign awsize  = axi_master_if.awsize  ;
      assign awburst = axi_master_if.awburst ;
      
      assign axi_master_if.awready = awready ;
      
      // WRITE DATA CHANNEL
      assign wvalid = axi_master_if.wvalid ;
      assign wdata  = axi_master_if.wdata  ;
      assign wstrb  = axi_master_if.wstrb  ;
      assign wlast  = axi_master_if.wlast  ;
      
      assign axi_master_if.wready = wready ;
      
      // WRITE RESPONSE CHANNEL
      assign bvalid = axi_master_if.bvalid ;
      assign bid    = axi_master_if.bid    ;
      
      assign axi_master_if.bready = bready ;
      
      
   axi_if#(32,32) axi_slave_if (aclk, aresetn) ;   
      // READ ADDRESS CHANNEL
      assign arvalid = axi_master_if.arvalid ;
      assign arid    = axi_master_if.arid    ;
      assign araddr  = axi_master_if.araddr  ;
      assign arlen   = axi_master_if.arlen   ;
      assign arsize  = axi_master_if.arsize  ;
      assign arburst = axi_master_if.arburst ;
      
      assign axi_master_if.arready = arready ;
      
      // READ DATA CHANNEL      
      assign axi_master_if.rvalid = rvalid ;
      assign axi_master_if.rdata  = rdata  ;
      assign axi_master_if.rid    = rid    ;
      assign axi_master_if.rlast  = rlast  ;
      assign axi_master_if.rresp  = rresp  ;
      
      assign rready = axi_master_if.rready ;
      
      
   initial begin
      // Setting AXI MASTER interface
      uvm_config_db #(virtual interface axi_if#(32,32))::set(null,"*.master_env.*","axi_vif",axi_master_if);
      // Setting AXI SLAVE interface
      uvm_config_db #(virtual interface axi_if#(32,32))::set(null,"*.slave_env.*","axi_vif",axi_slave_if);
      // Start UVM components
      run_test();
   end  

endmodule
