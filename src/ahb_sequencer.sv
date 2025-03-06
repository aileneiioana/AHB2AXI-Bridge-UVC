//------------------------------------
// File name   : ahb_sequencer.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_SEQUENCER_SV
`define AHB_SEQUENCER_SV

class ahb_sequencer #(AW=32,DW=32) extends uvm_sequencer #(ahb_trans #(AW,DW));

   `uvm_component_utils(ahb_sequencer #(AW,DW))
   
  function new(input string name, uvm_component parent);
      super.new(name, parent);
  endfunction : new
  
endclass:ahb_sequencer

`endif
