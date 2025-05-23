//------------------------------------
// File name   : virtual_sequencer.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

typedef class test_base;

class virtual_sequencer extends uvm_sequencer;

   `uvm_component_utils(virtual_sequencer)

   //Other sequencer pointers
   axi_sequencer #(32,32) axi_master_seqr;
   axi_sequencer #(32,32) axi_slave_seqr;
   
   test_base p_test_base;
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction:new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
   endfunction:build_phase

endclass:virtual_sequencer

class virtual_sequence_base extends uvm_sequence;

  `uvm_object_utils(virtual_sequence_base)
   // Declare which is the virtual sequencer
   `uvm_declare_p_sequencer(virtual_sequencer)
  
  function new(string name = "virtual_sequence_base");
    super.new(name);
  endfunction:new
  
  // Raising objection before starting body
  virtual task pre_body();
     starting_phase.raise_objection(this);
  endtask
  
  // Droping objection after finishing body
  virtual task post_body();
     starting_phase.drop_objection(this);
  endtask
  
endclass:virtual_sequence_base
  
