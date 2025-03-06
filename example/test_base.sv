//------------------------------------
// File name   : test_base.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`include "virtual_sequencer.sv"
`include "ahb2axi_scoreboard.sv"

class test_base extends uvm_test;

   `uvm_component_utils(test_base )
   
   ahb_env#(32,32) master_env;
   axi_env#(32,32) slave_env;
   virtual_sequencer v_sequencer;
   
   ahb2axi_scoreboard scoreboard;
   
   axi_user_callback mon_clbk;
   ahb_user_callback mon_clbk1;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   
   virtual function void build_phase(uvm_phase phase);
      // Configuration

      uvm_config_db #(uvm_bitstream_t)::set(this,"master_env.agent", "agent_kind", AHB_MASTER);
      uvm_config_db #(uvm_bitstream_t)::set(this,"master_env.agent", "is_active", UVM_ACTIVE);
      uvm_config_db #(int)::set(this,"master_env.agent.monitor", "has_checks", 1);
      uvm_config_db #(int)::set(this,"master_env.agent.monitor", "has_coverage", 1);
      uvm_config_db #(int)::set(this,"master_env.agent.driver", "idle_enable", 1);
      uvm_config_db #(int)::set(this,"master_env.agent.driver", "busy_enable", 1);
      uvm_config_db #(int)::set(this,"master_env.agent.driver", "one_kb_boundry_enable", 1);
       
      uvm_config_db #(uvm_bitstream_t)::set(this,"slave_env.agent", "agent_kind", AXI_SLAVE);
      uvm_config_db #(uvm_bitstream_t)::set(this,"slave_env.agent", "is_active", UVM_ACTIVE);
      uvm_config_db #(int)::set(this,"slave_env.agent.monitor", "has_checks", 1);
      uvm_config_db #(int)::set(this,"slave_env.agent.monitor", "has_coverage", 1);
      uvm_config_db #(int)::set(this,"scoreboard", "has_checks", 1);
      uvm_config_db #(int)::set(this,"scoreboard", "has_coverage", 1);

     super.build_phase(phase);
      
      master_env  = ahb_env#(32,32)::type_id::create("master_env",this);
      slave_env   = axi_env#(32,32)::type_id::create("slave_env",this);
      v_sequencer = virtual_sequencer::type_id::create("v_sequencer",this);
      
      scoreboard = ahb2axi_scoreboard::type_id::create("ahb2axi_scoreboard",this);
      
      mon_clbk = axi_user_callback::type_id::create(" mon_clbk ", this);
      mon_clbk1 = ahb_user_callback::type_id::create(" mon_clbk1 ", this);
   endfunction
   
   // Connect pointers of virtual sequencer
   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      v_sequencer.ahb_master_seqr = master_env.agent.sequencer;
      v_sequencer.axi_slave_seqr  = slave_env.agent.sequencer;
      v_sequencer.p_test_base = this;
      
      master_env.agent.monitor.item_collected_port.connect(scoreboard.master_export);
      slave_env.agent.monitor.item_collected_port.connect(scoreboard.slave_export);
      scoreboard.number_of_write_transfers_outstanding=slave_env.agent.driver.number_of_write_transfers_outstanding;
      scoreboard.number_of_read_transfers_outstanding=slave_env.agent.driver.number_of_read_transfers_outstanding;
      scoreboard.outstanding=slave_env.agent.driver.outstanding;
      uvm_callbacks#(axi_monitor, axi_callback)::add(slave_env.agent.monitor, mon_clbk);
      uvm_callbacks#(ahb_monitor, ahb_callback)::add(master_env.agent.monitor, mon_clbk1);
   endfunction:connect_phase

   virtual function void end_of_elaboration_phase(uvm_phase phase);
      uvm_top.print_topology();
   endfunction

endclass
