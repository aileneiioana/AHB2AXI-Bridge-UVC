//------------------------------------
// File name   : axi_env.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

`include "axi_trans.sv"
`uvm_analysis_imp_decl(_axi_master) // uvm_macro to declare an analysis import
`uvm_analysis_imp_decl(_axi_slave)  // uvm_macro to declare an analysis import

class axi_scoreboard #(AW=32,DW=32) extends uvm_scoreboard;

  `uvm_component_utils(axi_scoreboard)
  
  uvm_analysis_imp_axi_master #(axi_trans#(32, 32), axi_scoreboard) master_export;
  uvm_analysis_imp_axi_slave #(axi_trans#(32, 32), axi_scoreboard) slave_export;

   protected axi_trans#(32, 32) master_trans;
   protected axi_trans#(32, 32) slave_trans;
   
  axi_trans#(32, 32)  master_transfers [$];
  axi_trans#(32, 32)  slave_transfers  [$];

  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_export = new("master_export", this);
    slave_export = new("slave_export", this);
  endfunction: build_phase
  
    function void write_axi_master(input axi_trans#(32, 32) item);
        $cast(master_trans,item);
        master_transfers.push_back(master_trans);
      //   `uvm_info(get_type_name(), $sformatf("The Scoreboard received this MASTER transfer:\n%s",master_trans.sprint()), UVM_LOW)
    endfunction
    
    function void write_axi_slave(input axi_trans#(32, 32) item);
        $cast(slave_trans,item);
        slave_transfers.push_back(slave_trans);
      //   `uvm_info(get_type_name(), $sformatf("The Scoreboard received this SLAVE transfer:\n%s",slave_trans.sprint()), UVM_LOW)
    endfunction
    
 function void check_phase(uvm_phase phase);
    super.build_phase(phase);
    
    `uvm_info(get_type_name(), $sformatf("The Scoreboard done checking %d Master transactions and %d Slave transactions",master_transfers.size, slave_transfers.size), UVM_LOW)
  endfunction: check
   


endclass : axi_scoreboard
`endif
