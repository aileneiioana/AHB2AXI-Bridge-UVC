//------------------------------------
// File name   : test_example_3.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

class master_example_seq_3 extends virtual_sequence_base;

   ahb_trans #(32,32) ahb_read, ahb_write;
   
   `uvm_object_utils(master_example_seq_3)   

   function new(string name = "master_example_seq_3");
      super.new(name);
   endfunction:new 
   
   virtual task body();
   /* for(int i=0;i<9999999;i++)
     `uvm_do_on(ahb_write, p_sequencer.ahb_master_seqr)
    //`uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_burst_type != SINGLE;})

  
  `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_burst_type == SINGLE; ahb_op_type == AHB_WRITE;ahb_trans_delay == 1;})
*/
  
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR4;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR4;  ahb_size_type==HWORD; ahb_trans_delay == 0;})    
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR4;  ahb_size_type==BYTE;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR8;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR8;  ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR8;  ahb_size_type==BYTE;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR16; ahb_size_type==BYTE;  ahb_trans_delay == 0;})     
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR16; ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == INCR16; ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP4;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP4;  ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP4;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP8;  ahb_size_type==BYTE;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP8;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP8;  ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP16; ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP16; ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == WRAP16; ahb_size_type==BYTE;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == SINGLE; ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == SINGLE; ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_read,  p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ;  ahb_burst_type == SINGLE; ahb_size_type==BYTE;  ahb_trans_delay == 0;})
   
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR4;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR4;  ahb_size_type==HWORD; ahb_trans_delay == 0;})    
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR4;  ahb_size_type==BYTE;  ahb_trans_delay == 0;}) 
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR8;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR8;  ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR8;  ahb_size_type==BYTE;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR16; ahb_size_type==BYTE;  ahb_trans_delay == 0;})     
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR16; ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == INCR16; ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP4;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP4;  ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP4;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP8;  ahb_size_type==BYTE;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP8;  ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP8;  ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP16; ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP16; ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == WRAP16; ahb_size_type==BYTE;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == SINGLE; ahb_size_type==WORD;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == SINGLE; ahb_size_type==HWORD; ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == SINGLE; ahb_size_type==BYTE;  ahb_trans_delay == 0;})
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; ahb_burst_type == SINGLE; ahb_size_type==BYTE;  ahb_trans_delay == 1;})

   #250ns;   
   endtask

endclass

class slave_example_seq_3 extends virtual_sequence_base;

   ahb_trans #(32,32) trans;
   
   `uvm_object_utils(slave_example_seq_3)   

   function new(string name = "slave_example_seq_3");
      super.new(name);
   endfunction:new 
  
   virtual task body();
    `uvm_do_on(trans, p_sequencer.ahb_slave_seqr)
    #200ns;   
   endtask

endclass

// Virtual sequence made out of AHB UVC sequences
class ahb_example_seq_3 extends virtual_sequence_base;

   master_example_seq_3 master_seq;
   slave_example_seq_3 slave_seq;

   `uvm_object_utils(ahb_example_seq_3)

   function new(string name = "ahb_example_seq_3");
      super.new(name);
   endfunction:new 
     
   virtual task body();
     // start reactive slave sequence to work in backround -it will run forever
     fork
       `uvm_do(slave_seq);
     join_any
     
     // start and then wait the master sequence to finish, before ending the test
     fork
       `uvm_do(master_seq);
     join
     `uvm_info(get_name(), $sformatf("TEST DONE"), UVM_LOW) 
   endtask

endclass

class test_example_3 extends test_base;

   `uvm_component_utils(test_example_3)

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   
   virtual function void build_phase(uvm_phase phase);
      // Configuration
      uvm_config_db #(uvm_object_wrapper)::set(this,"v_sequencer.run_phase", "default_sequence", ahb_example_seq_3::get_type());

      super.build_phase(phase);
   endfunction
   
endclass
