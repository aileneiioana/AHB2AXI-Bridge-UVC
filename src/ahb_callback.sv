//------------------------------------
// File name   : ahb_callback.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_CALLBACK_SV
`define AHB_CALLBACK_SV

class ahb_callback extends uvm_callback;
   
    `uvm_object_utils(ahb_callback)
   
    function new(string name = "ahb_callback");
      super.new(name);
    endfunction
    
    virtual task counts_number_of_wait_hreadyout; 
    endtask 
    
    virtual task zero_number_of_wait_hreadyout; 
    endtask 

    
endclass: ahb_callback

`endif 