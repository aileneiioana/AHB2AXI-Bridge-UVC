//------------------------------------
// File name   : axi _sequences.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_SEQS_SV
`define AXI_SEQS_SV

class axi_base_seq #(AW=32,DW=32) extends uvm_sequence #(axi_trans #(AW,DW));

  `uvm_object_utils(axi_base_seq)
  
  function new(string name = "axi_base_seq");
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
  
endclass:axi_base_seq

`endif
