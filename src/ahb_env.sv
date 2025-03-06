//------------------------------------
// File name   : ahb_env.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_ENV_SV
`define AHB_ENV_SV

class ahb_env #(AW=32,DW=32) extends uvm_env;

   `uvm_component_utils(ahb_env#(AW,DW))

   //AHB agent
   ahb_agent agent;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction:new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      //create the wb agent
      agent = ahb_agent#(AW,DW)::type_id::create("agent",this);
   endfunction:build_phase

endclass
`endif
