//------------------------------------
// File name   : ahb _sequences.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_SEQS_SV
`define AHB_SEQS_SV

class ahb_base_seq #(AW=32,DW=32) extends uvm_sequence #(ahb_trans #(AW,DW));

  `uvm_object_utils(ahb_base_seq)
  
  function new(string name = "ahb_base_seq");
    super.new(name);
  endfunction:new
  
  // Raising objection before starting body
  virtual task pre_body();
     starting_phase.raise_objection(this);
  endtask
  
  // Droping objection after finishing body
  virtual task post_body();
     starting_phase.drop_objection(this);
  endtask
  
endclass:ahb_base_seq

`endif
