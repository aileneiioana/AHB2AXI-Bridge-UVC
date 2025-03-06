 //------------------------------------
// File name   : user_callback.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_USER_CALLBACK_SV
`define AXI_USER_CALLBACK_SV

class axi_user_callback extends axi_callback;

     int unsigned number_of_reads_finished  = 0;
     int unsigned number_of_writes_finished = 0;
   
    `uvm_object_utils(axi_user_callback)

   
    function new(string name = "axi_user_callback");
      super.new(name);
    endfunction
    
    
    task counts_finished_reads; 
      number_of_reads_finished ++;
      //`uvm_info(get_name(), $sformatf("counts_finished_reads %d", number_of_reads_finished), UVM_LOW)
    endtask 

    task counts_finished_writes;
      number_of_writes_finished ++;
      //`uvm_info(get_name(), $sformatf("counts_finished_writes %d", number_of_writes_finished), UVM_LOW)
    endtask
    
endclass: axi_user_callback

`endif 