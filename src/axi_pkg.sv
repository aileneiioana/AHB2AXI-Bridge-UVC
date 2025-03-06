//------------------------------------
// File name   : axi_pkg.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_PKG_SV
`define AXI_PKG_SV

package axi_pkg;
   import uvm_pkg::*;

    `include "uvm_macros.svh"
    `include "axi_types.sv"
    `include "axi_trans.sv"
    `include "axi_callback.sv"
    `include "axi_user_callback.sv"
    `include "axi_sequencer.sv"
    `include "axi_driver.sv"
    `include "axi_monitor.sv"
    `include "axi_agent.sv"
    `include "axi_env.sv"
    `include "axi_sequences.sv"
  
endpackage:axi_pkg

`endif
