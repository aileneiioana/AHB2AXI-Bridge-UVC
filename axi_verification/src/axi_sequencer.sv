//------------------------------------
// File name   : axi_sequencer.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_SEQUENCER_SV
`define AXI_SEQUENCER_SV

class axi_sequencer #(AW=32,DW=32) extends uvm_sequencer #(axi_trans #(AW,DW));
 
   `uvm_component_utils(axi_sequencer #(AW,DW))
   
  function new(input string name, uvm_component parent);
      super.new(name, parent);
  endfunction : new
  
endclass:axi_sequencer

`endif
