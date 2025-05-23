//------------------------------------
// File name   : ahb_env.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_SCOREBOARD_SV
`define AHB_SCOREBOARD_SV

`include "ahb_trans.sv"
`uvm_analysis_imp_decl(_ahb_master)  // uvm_macro to declare an analysis import
`uvm_analysis_imp_decl(_ahb_slave)  // uvm_macro to declare an analysis import

class ahb_scoreboard #(AW=32,DW=32) extends uvm_scoreboard;

  `uvm_component_utils(ahb_scoreboard)
  
  uvm_analysis_imp_ahb_master #(ahb_trans#(32, 32), ahb_scoreboard) master_export;
  uvm_analysis_imp_ahb_slave #(ahb_trans#(32, 32), ahb_scoreboard) slave_export;

   protected ahb_trans#(32, 32) master_trans;
   protected ahb_trans#(32, 32) slave_trans;
   
  ahb_trans#(32, 32)  master_transfers [$];
  ahb_trans#(32, 32)  slave_transfers  [$];

  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_export = new("master_export", this);
    slave_export = new("slave_export", this);
  endfunction: build_phase
  
    function void write_ahb_master(input ahb_trans#(32, 32) item);
        $cast(master_trans,item);
        master_transfers.push_back(master_trans);
      //   `uvm_info(get_type_name(), $sformatf("The Scoreboard received this MASTER transfer:\n%s",master_trans.sprint()), UVM_LOW)
    endfunction
    
        function void write_ahb_slave(input ahb_trans#(32, 32) item);
        $cast(slave_trans,item);
        slave_transfers.push_back(slave_trans);
      //   `uvm_info(get_type_name(), $sformatf("The Scoreboard received this SLAVE transfer:\n%s",slave_trans.sprint()), UVM_LOW)
    endfunction
    
 function void check_phase(uvm_phase phase);
    super.build_phase(phase);
    if(master_transfers.size != slave_transfers.size())
      uvm_report_error("SCOREBOARD Number of Transfers not the same at time $t" , "Master Monitot sent %d items, Slave Monitor sent %d items",master_transfers.size,slave_transfers.size );
    for(int i=0;i< master_transfers.size; i++) begin
       if(master_transfers[i].ahb_op_type != slave_transfers[i].ahb_op_type)
        uvm_report_error("SCOREBOARD HWRITE not the same " , "Master Operation %d, Slave Operation %d",,master_transfers[i].ahb_op_type,slave_transfers[i].ahb_op_type);
       if(master_transfers[i].ahb_burst_type != slave_transfers[i].ahb_burst_type)
        uvm_report_error("SCOREBOARD HBURST not the same " , "Master Burst %d, Slave Burst %d" ,master_transfers[i].ahb_burst_type,slave_transfers[i].ahb_burst_type);
       if(master_transfers[i].ahb_size_type != slave_transfers[i].ahb_size_type)
        uvm_report_error("SCOREBOARD HSIZE not the same " , "Master Size %d, Slave Size %d",master_transfers[i].ahb_size_type,slave_transfers[i].ahb_size_type);
       if(master_transfers[i].ahb_wstrobe != slave_transfers[i].ahb_wstrobe)
        uvm_report_error("SCOREBOARD HWSTROBE not the same " , "Master Strobe %d, Slave Strobe %d",master_transfers[i].ahb_wstrobe,slave_transfers[i].ahb_wstrobe );
     if(master_transfers[i].start_addr != slave_transfers[i].start_addr)
        uvm_report_error("SCOREBOARD Address not the same " , "Master Address %h, Slave Address %h",master_transfers[i].start_addr,slave_transfers[i].start_addr );
       if(master_transfers[i].ahb_data.size != slave_transfers[i].ahb_data.size())
      uvm_report_error("SCOREBOARD Number of Data Collected not the same " , "Master Monitot sent %d items, Slave Monitor sent %d items", master_transfers[i].ahb_data.size,slave_transfers[i].ahb_data.size);
      for(int j = 0; j< master_transfers[i].ahb_data.size; j++)
       if(master_transfers[i].ahb_data[j] != slave_transfers[i].ahb_data[j]) 
        uvm_report_error("SCOREBOARD Data Collected not the same " , "Master Monitot sent %h, Slave Monitor sent %h" ,master_transfers[i].ahb_data[j],slave_transfers[i].ahb_data[j]);
    end
      `uvm_info(get_type_name(), $sformatf("The Scoreboard done checking %d Master transactions and %d Slave transactions",master_transfers.size, slave_transfers.size), UVM_LOW)
  endfunction: check
   


endclass : ahb_scoreboard
`endif
