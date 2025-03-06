 //------------------------------------
// File name   : ahb_user_callback.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_USER_CALLBACK_SV
`define AHB_USER_CALLBACK_SV

class ahb_user_callback extends ahb_callback;

     int unsigned number_of_wait_hreadyout = 0;
     event need_test_finished;
   
    `uvm_object_utils(ahb_user_callback)

   
    function new(string name = "ahb_user_callback");
      super.new(name);
    endfunction
    
    
    task counts_number_of_wait_hreadyout; 
      number_of_wait_hreadyout ++;
     // `uvm_info(get_name(), $sformatf("counts_number_of_wait_hreadyout %d", number_of_wait_hreadyout), UVM_LOW)
    endtask 
    
    task zero_number_of_wait_hreadyout; 
      number_of_wait_hreadyout = 0;
    //  `uvm_info(get_name(), $sformatf("counts_number_of_wait_hreadyout %d", number_of_wait_hreadyout), UVM_LOW)
    endtask 

    
endclass: ahb_user_callback

`endif 