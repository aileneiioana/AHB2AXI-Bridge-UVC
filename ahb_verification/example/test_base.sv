//------------------------------------
// File name   : test_base.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`include "virtual_sequencer.sv"
`include "ahb_scoreboard.sv"

class test_base extends uvm_test;

   `uvm_component_utils(test_base)
   
   ahb_env#(32,32) master_env;
   ahb_env#(32,32) slave_env;
   virtual_sequencer v_sequencer;
   
   ahb_scoreboard scoreboard;
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   
   virtual function void build_phase(uvm_phase phase);
      // Configuration
      uvm_config_db #(uvm_bitstream_t)::set(this,"master_env.agent", "agent_kind", AHB_MASTER);
      uvm_config_db #(uvm_bitstream_t)::set(this,"master_env.agent", "is_active", UVM_ACTIVE);
      uvm_config_db #(int)::set(this,"master_env.agent.monitor", "has_checks", 1);
      uvm_config_db #(int)::set(this,"master_env.agent.monitor", "has_coverage", 1);
      uvm_config_db #(uvm_bitstream_t)::set(this,"slave_env.agent", "agent_kind", AHB_SLAVE);
      uvm_config_db #(uvm_bitstream_t)::set(this,"slave_env.agent", "is_active", UVM_ACTIVE);
      uvm_config_db #(int)::set(this,"slave_env.agent.monitor", "has_checks", 1);
      uvm_config_db #(int)::set(this,"slave_env.agent.monitor", "has_coverage", 1);
      uvm_config_db #(int)::set(this,"slave_env.agent.driver", "reactive_slave", 0);
      uvm_config_db #(int)::set(this,"slave_env.agent.driver", "probability_of_ERROR", 2);
      
       uvm_config_db #(int)::set(this,"master_env.agent.driver", "idle_enable", 1);
       uvm_config_db #(int)::set(this,"master_env.agent.driver", "busy_enable", 1);
       uvm_config_db #(int)::set(this,"slave_env.agent.driver", "hresp_error_enable", 1);
       uvm_config_db #(int)::set(this,"master_env.agent.driver", "one_kb_boundry_enable", 1);
       
       
      super.build_phase(phase);
      
      master_env  = ahb_env#(32,32)::type_id::create("master_env",this);
      slave_env   = ahb_env#(32,32)::type_id::create("slave_env",this);
      v_sequencer = virtual_sequencer::type_id::create("v_sequencer",this);
      
      scoreboard = ahb_scoreboard::type_id::create("ahb_scoreboard",this);
      
   endfunction
   
   // Connect pointers of virtual sequencer
   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      v_sequencer.ahb_master_seqr = master_env.agent.sequencer;
      v_sequencer.ahb_slave_seqr  = slave_env.agent.sequencer;
      v_sequencer.p_test_base = this;
      
      master_env.agent.monitor.item_collected_port.connect(scoreboard.master_export);
      slave_env.agent.monitor.item_collected_port.connect(scoreboard.slave_export);
      

   endfunction:connect_phase

   virtual function void end_of_elaboration_phase(uvm_phase phase);
      uvm_top.print_topology();
   endfunction

endclass
