//------------------------------------
// File name   : axi_trans.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_TRANS_SV
`define AXI_TRANS_SV
 
class axi_trans #(AW=32,DW=32) extends uvm_sequence_item;

  `uvm_object_utils(axi_trans)

  function new (string name = "axi_trans");
    super.new(name);
  endfunction
 

endclass:axi_trans

`endif