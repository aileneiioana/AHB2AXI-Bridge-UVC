//------------------------------------
// File name   : axi_callback.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_CALLBACK_SV
`define AXI_CALLBACK_SV

class axi_callback extends uvm_callback;
   
    `uvm_object_utils(axi_callback)
   
    function new(string name = "axi_callback");
      super.new(name);
    endfunction
    
    virtual task counts_finished_reads; 
    endtask 

    virtual task counts_finished_writes;
    endtask
    
endclass: axi_callback

`endif 