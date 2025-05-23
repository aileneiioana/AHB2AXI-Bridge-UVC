//------------------------------------
// File name   : axi_if.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_IF_SV
`define AXI_IF_SV

interface axi_if #(AW=32,DW=32) (input aclk,input aresetn);
 
  // WRITE ADDRESS CHANNEL
   wire          awvalid ; // Write request
   wire [   3:0] awid    ; // Write ID. Between 0 and 15
   wire [AW-1:0] awaddr  ; // Write address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)
   wire [   3:0] awlen   ; // Burst length (no of cycles in burst - 1)
   wire [   2:0] awsize  ; // Byte, Halfword, Word. Byte and Halfword is supported only if burst length is 1.
   wire [   1:0] awburst ; // Burst type: FIXED, INCR, WRAP
   wire          awready ; // Write request acknowledge
   
   // WRITE DATA CHANNEL
   wire          wvalid  ; // Write data valid
   wire [DW-1:0] wdata   ; // Write data
   wire [   3:0] wstrb   ; // Write strobe. For bursts (more than 1 cycle) is all ones. 
                           // For bursts of 1 cycle, it can be between 1 and 15.  
                           // If size is not Word, make sure the bits set to 1 are matching the selected Bytes.
   wire          wlast   ; // Write data last
   wire          wready  ; // Write data ready
   
   // WRITE RESPONSE CHANNEL
   wire          bvalid  ; // Write response valid
   wire [   3:0] bid     ; // Write response ID.
   wire          bready  ; // Write response ready - stuck to 1
   
   // READ ADDRESS CHANNEL
   wire          arvalid ; // Read request
   wire [   3:0] arid    ; // Read ID. Between 0 and 15
   wire [AW-1:0] araddr  ; // Read address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)
   wire [   3:0] arlen   ; // Burst length (no of cycles in burst - 1)
   wire [   2:0] arsize  ; // Byte, Halfword, Word. Byte and Halfword is supported only if burst length is 1.
   wire [   1:0] arburst ; // Burst type: FIXED, INCR, WRAP
   wire          arready ; // Read request acknowledge
   
   // READ DATA CHANNEL
   wire          rvalid  ; // Read data valid
   wire [DW-1:0] rdata   ; // Read data
   wire [   3:0] rid     ; // Read data last
   wire          rlast   ; // Read response ID.
   wire [   1:0] rresp   ; // Read response status: all posibilities supported
   wire          rready  ; // Read data ready.

   bit           has_checks;
   
  //master clocking block
  clocking mst_cb @(posedge aclk);
    // WRITE ADDRESS CHANNEL
    input   awready ;
    output  awvalid ,
            awid    ,
            awaddr  ,
            awlen   ,
            awsize  ,
            awburst ;
            
    // WRITE DATA CHANNEL
    input   wready  ;
    output  wvalid  ,
            wdata   ,
            wstrb   ,
            wlast   ;
            
    // WRITE RESPONSE CHANNEL
    input   bvalid  ,
            bid     ;
    output  bready  ;
    
    // READ ADDRESS CHANNEL
    input   arready ;
    output  arvalid ,
            arid    ,
            araddr  ,
            arlen   ,
            arsize  ,
            arburst ;
            
    // READ DATA CHANNEL
    input   rvalid  ,
            rdata   ,
            rid     ,
            rlast   ,
            rresp   ;
    output  rready  ;
    
  endclocking:mst_cb  
 
  //slave clocking block
  clocking slv_cb @(posedge aclk);
   // WRITE ADDRESS CHANNEL
    input   awvalid ,
            awid    ,
            awaddr  ,
            awlen   ,
            awsize  ,
            awburst ;
    output  awready ;
    
    // WRITE DATA CHANNEL
    input   wvalid  ,
            wdata   ,
            wstrb   ,
            wlast   ;
    output  wready  ;
    
    // WRITE RESPONSE CHANNEL
    input   bready  ;
    output  bvalid  ,
            bid     ;
            
    // READ ADDRESS CHANNEL
    input   arvalid ,
            arid    ,
            araddr  ,
            arlen   ,
            arsize  ,
            arburst ;
    output  arready ;
    
    // READ DATA CHANNEL
    input   rready  ;
    output  rvalid  ,
            rdata   ,
            rid     ,
            rlast   ,
            rresp   ;

  endclocking:slv_cb
 
  //monitor clocking block - all signals are inputs
  clocking mon_cb @(posedge aclk);
     // WRITE ADDRESS CHANNEL
    input   awvalid ,
            awid    ,
            awaddr  ,
            awlen   ,
            awsize  ,
            awburst ,
            awready ;
            
    // WRITE DATA CHANNEL
    input   wvalid  ,
            wdata   ,
            wstrb   ,
            wlast   ,
            wready  ;
            
    // WRITE RESPONSE CHANNEL
    input   bready  ,
            bvalid  ,
            bid     ;
            
    // READ ADDRESS CHANNEL
    input   arvalid ,
            arid    ,
            araddr  ,
            arlen   ,
            arsize  ,
            arburst ,
            arready ;
            
   // READ DATA CHANNEL
    input   rready  ,
            rvalid  ,
            rdata   ,
            rid     ,
            rlast   ,
            rresp   ;
                       
  endclocking:mon_cb

//******************************************************************** PROTOCOL ASSERTIONS ************************************************************//
// As long a transaction is processed, data should not be X or Z

// Output values under reset

// bvalid is LOW for the first cycle after aresetn goes HIGH

// A slave must not take bvalid HIGH until after the last write data handshake is complete

// Once bvalid is asserted, it must remain asserted until bready is HIGH

// bid must remain stable when bvalid is asserted and bready LOW

// rvalid is LOW for the first cycle after aresetn goes HIGH

// rdata, rid, rlast, rresp must remain stable when rvalid is asserted and rready LOW

// Once rvalid is asserted, it must remain asserted and rready LOW

// Check if the arid is the same with the rid on a read transaction

// The number of read data items must match the corresponding ARLEN

endinterface
`endif