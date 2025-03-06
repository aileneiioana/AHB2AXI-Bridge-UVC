//------------------------------------
// File name   : test_example_11.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

class master_example_seq_10 extends virtual_sequence_base;

   ahb_trans #(32,32) ahb_write;
   int i;
   `uvm_object_utils(master_example_seq_10)   

   function new(string name = "master_example_seq_10");
      super.new(name);
   endfunction:new 

   virtual task body();
    `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; addr_mode ==0; ahb_burst_type == SINGLE; ahb_size_type == 3'b010; ahb_trans_delay == 10; ahb_wstrobe == 'hF; ahb_data[0] == 'h0000_2003;})     
    // `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; start_addr == 32'h100; ahb_burst_type == SINGLE; ahb_size_type == 3'b010; ahb_trans_delay == 10; ahb_wstrobe == 'hF; ahb_data[0] == 'b00000000000000000000000000000010;})     
    
   for( i=0;i<=300;i++) 
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_WRITE; addr_mode ==1; ahb_burst_type == INCR16 ; ahb_trans_delay ==0;})
    for( i=0;i<=31;i++) 
     `uvm_do_on_with(ahb_write, p_sequencer.ahb_master_seqr, { ahb_op_type == AHB_READ; addr_mode ==1; ahb_burst_type == INCR16 ;})
    #200ns;
   endtask

endclass


class slave_example_seq_10 extends virtual_sequence_base;

   axi_trans #(32,32) trans;
   
   `uvm_object_utils(slave_example_seq_10)   

   function new(string name = "slave_example_seq_10");
      super.new(name);
   endfunction:new 
   
   virtual task body();
      `uvm_do_on_with(trans, p_sequencer.axi_slave_seqr,{ })
      #200ns;
   endtask

endclass

// Virtual sequence made out of axi UVC sequences
class ahb2axi_example_seq_11 extends virtual_sequence_base;

   master_example_seq_10 master_seq;
   slave_example_seq_10  slave_seq;

   `uvm_object_utils(ahb2axi_example_seq_11)

   function new(string name = "ahb2axi_example_seq_11");
      super.new(name);
   endfunction:new 
   
   task stop_test();
     while(1)begin
        wait(p_sequencer.p_test_base.mon_clbk1.number_of_wait_hreadyout >1000); $display("%d",p_sequencer.p_test_base.mon_clbk1.number_of_wait_hreadyout );
          master_seq.kill();
          slave_seq.kill();
        #2;
       end
   endtask
   
   virtual task body();
    fork
      fork
        `uvm_do(master_seq);
        `uvm_do(slave_seq);
      join
      
      stop_test();
    join_any
    disable fork;
   endtask

endclass


class test_example_11 extends test_base;
  
   `uvm_component_utils(test_example_11)

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   
   virtual function void build_phase(uvm_phase phase);
      // Configuration
      uvm_config_db #(uvm_object_wrapper)::set(this,"v_sequencer.run_phase", "default_sequence", ahb2axi_example_seq_11::get_type());
      
      uvm_config_db #(int)::set(this,"slave_env.agent.driver", "outstanding", 1);
      uvm_config_db #(int)::set(this,"slave_env.agent.driver", "number_of_write_transfers_outstanding", 32);
      uvm_config_db #(int)::set(this,"slave_env.agent.driver", "number_of_read_transfers_outstanding", 1);
      uvm_config_db #(int)::set(this,"slave_env.agent.monitor", "outstanding", 1);
      uvm_config_db #(int)::set(this,"slave_env.agent.monitor", "number_of_write_transfers_outstanding", 32);
      uvm_config_db #(int)::set(this,"slave_env.agent.monitor", "number_of_read_transfers_outstanding", 1);
      super.build_phase(phase);

   endfunction
   
   
endclass
