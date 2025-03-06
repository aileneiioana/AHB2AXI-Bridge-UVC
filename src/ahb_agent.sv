//------------------------------------
// File name   : ahb_agent.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_AGENT_SV
`define AHB_AGENT_SV

class ahb_agent #(AW=32,DW=32) extends uvm_agent;

   ahb_agent_kind_t agent_kind;
   
   ahb_monitor   #(AW,DW) monitor;
   ahb_sequencer #(AW,DW) sequencer;
   ahb_driver    #(AW,DW) driver;
   
      
   `uvm_component_utils_begin(ahb_agent #(AW,DW))
      `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
      `uvm_field_enum(ahb_agent_kind_t, agent_kind, UVM_ALL_ON)
   `uvm_component_utils_end

   function new(string name, uvm_component parent = null);
      super.new(name, parent);
   endfunction:new 

   //create the agent's subcomponents
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      //get agent type:active or passive
      if (!uvm_config_db#(uvm_bitstream_t)::get(this,"","is_active", is_active))
      begin
	       `uvm_fatal(get_type_name(), {"Agent type must be set for: ",get_full_name(),""})       
      end
      
      if (!uvm_config_db#(uvm_bitstream_t)::get(this,"","agent_kind", agent_kind))
      begin
	       `uvm_fatal(get_type_name(), {"Agent kind must be set for: ",get_full_name(),""})       
      end

      //create the monitor
      monitor = ahb_monitor#(AW,DW)::type_id::create("monitor", this);
      
      if(is_active == UVM_ACTIVE)
      begin
	      //create the sequencer
	      sequencer = ahb_sequencer#(AW,DW)::type_id::create("sequencer", this);
        //create the driver  
	      driver = ahb_driver#(AW,DW)::type_id::create("driver", this);
      end
   endfunction:build_phase

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if(is_active == UVM_ACTIVE) begin
         //connect the driver to the sequencer
	       driver.seq_item_port.connect(sequencer.seq_item_export);
	       driver.agent_kind = agent_kind;
      end
      
   endfunction:connect_phase

endclass

`endif
