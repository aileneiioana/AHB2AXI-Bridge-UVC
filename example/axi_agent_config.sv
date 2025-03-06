//------------------------------------
// File name   : axi_agent_config.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------


class axi_agent_config  extends uvm_object;


  bit has_checks     = 1'b1; 
  bit has_coverage   = 1'b1;
  bit four_kb_boundary_enable = 1;
  int unsigned number_of_write_transfers_outstanding ;
  int unsigned number_of_read_transfers_outstanding = 0;
  bit outstanding ;
  
  int number_of_transactions = 100;
  
  real period = 1.66;
  
  `uvm_object_utils_begin(axi_agent_config)
     `uvm_field_int(number_of_write_transfers_outstanding, UVM_ALL_ON)
     `uvm_field_int(outstanding, UVM_ALL_ON)
  `uvm_object_utils_end
     
  //extern function new (string name="axi_agent_config");
function new (string name="axi_agent_config");
  super.new(name);
endfunction : new
endclass : axi_agent_config


