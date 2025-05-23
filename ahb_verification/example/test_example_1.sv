//------------------------------------
// File name   : test_example_1.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

class master_example_seq extends virtual_sequence_base;

   ahb_trans #(32,32) ahb_read, ahb_write;
   
   uvm_status_e status;
   uvm_reg_data_t data;
   
   `uvm_object_utils(master_example_seq)   

   function new(string name = "master_example_seq");
      super.new(name);
   endfunction:new 
   
    virtual task body();
      for(int i=0;i<5000;i++)
      `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, {  ahb_burst_type == SINGLE; ahb_size_type==WORD; })
      `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == SINGLE; ahb_size_type==WORD; ahb_trans_delay == 3; })
      #200ns;
   endtask

endclass

class slave_example_seq extends virtual_sequence_base;

   ahb_trans #(32,32) trans;
   
   `uvm_object_utils(slave_example_seq)   

   function new(string name = "slave_example_seq");
      super.new(name);
   endfunction:new 
   
   virtual task body();
      `uvm_do_on_with(trans, p_sequencer.ahb_slave_seqr,{  ahb_burst_type ==INCR4; ahb_size_type==WORD; ahb_hready_kind == ALWAYS_1;})
      #200ns;
   endtask

endclass

// Virtual sequence made out of AHB UVC sequences
class ahb_example_seq_1 extends virtual_sequence_base;

   master_example_seq master_seq;
   slave_example_seq  slave_seq;

   `uvm_object_utils(ahb_example_seq_1)

   function new(string name = "ahb_example_seq_1");
      super.new(name);
   endfunction:new 
   
   virtual task body();
       fork
         `uvm_do(master_seq);
         `uvm_do(slave_seq);
      join
   endtask

endclass

class test_example_1 extends test_base;

   `uvm_component_utils(test_example_1)
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   
   virtual function void build_phase(uvm_phase phase);
      // Configuration
      uvm_config_db #(uvm_object_wrapper)::set(this,"v_sequencer.run_phase", "default_sequence", ahb_example_seq_1::get_type());

      super.build_phase(phase);
   endfunction
   
endclass
