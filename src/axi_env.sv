//------------------------------------
// File name   : axi_env.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_ENV_SV
`define AXI_ENV_SV

class axi_env #(AW=32,DW=32) extends uvm_env;

   `uvm_component_utils(axi_env#(AW,DW))

   //axi agent
   axi_agent agent;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction:new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      //create the wb agent
      agent = axi_agent#(AW,DW)::type_id::create("agent",this);
   endfunction:build_phase

endclass
`endif
