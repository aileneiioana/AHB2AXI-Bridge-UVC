`timescale 1ns/1ps

`include "ahb_if.sv"
`include "ahb_pkg.sv"

module tb_example();

   import uvm_pkg::*;
   `include "uvm_macros.svh"
   
   import ahb_pkg::*;
   `include "test_lib.sv"
   
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
      hclk = 0;
      hreset_n = 1'b1;
      #100ns;
      hreset_n = 1'b0;
      #100ns;
      hreset_n = 1'b1;
   end
   
   initial forever #0.83ns hclk =! hclk;
   
   // Interface instances
   ahb_if#(32,32) ahb_master_if (hclk, hreset_n);       
      assign hsel     = ahb_master_if.hsel      ;
      assign hwrite   = ahb_master_if.hwrite    ;
      assign htrans   = ahb_master_if.htrans    ;
      assign hburst   = ahb_master_if.hburst    ;
      assign hsize    = ahb_master_if.hsize     ;
      assign haddr    = ahb_master_if.haddr     ;
      assign hwdata   = ahb_master_if.hwdata    ;
      assign hwstrobe = ahb_master_if.hwstrobe  ;
      
      assign ahb_master_if.hrdata    = hrdata   ;
      assign ahb_master_if.hreadyout = hreadyout;
      assign ahb_master_if.hresp     = hresp    ;
   
   ahb_if#(32,32) ahb_slave_if (hclk, hreset_n) ;       
      assign ahb_slave_if.haddr    = haddr      ;
      assign ahb_slave_if.hsel     = hsel       ;
      assign ahb_slave_if.hwrite   = hwrite     ;
      assign ahb_slave_if.htrans   = htrans     ;
      assign ahb_slave_if.hburst   = hburst     ;  
      assign ahb_slave_if.hsize    = hsize      ;
      assign ahb_slave_if.hwdata   = hwdata     ;
      assign ahb_slave_if.hwstrobe = hwstrobe   ;
   
      assign hrdata    = ahb_slave_if.hrdata    ;
      assign hreadyout = ahb_slave_if.hreadyout ;
      assign hresp     = ahb_slave_if.hresp     ;
   
   initial begin
      // Setting AHB MASTER interface
      uvm_config_db #(virtual interface ahb_if#(32,32))::set(null,"*.master_env.*","ahb_vif",ahb_master_if);
      // Setting AHB SLAVE interface
      uvm_config_db #(virtual interface ahb_if#(32,32))::set(null,"*.slave_env.*","ahb_vif",ahb_slave_if);
      // Start UVM components
      run_test();
   end  

endmodule
