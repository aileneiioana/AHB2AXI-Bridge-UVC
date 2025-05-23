//------------------------------------
// File name   : ahb_pkg.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_PKG_SV
`define AHB_PKG_SV

package ahb_pkg;
   import uvm_pkg::*;

    `include "uvm_macros.svh"
    `include "ahb_types.sv"
    `include "ahb_trans.sv"
    `include "ahb_sequencer.sv"
    `include "ahb_driver.sv"
    `include "ahb_monitor.sv"
    `include "ahb_agent.sv"
    `include "ahb_env.sv"
    `include "ahb_sequences.sv"
  
endpackage:ahb_pkg

`endif
