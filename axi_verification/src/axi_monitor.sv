//------------------------------------
// File name   : axi_monitor.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_MON_SV
`define AXI_MON_SV


class axi_monitor #(AW=32,DW=32) extends uvm_monitor;

   //analysis port for axi transaction
   uvm_analysis_port #(axi_trans#(AW,DW)) item_collected_port;

   //axi interface
   virtual axi_if #(AW,DW) vif;

   //collected transaction 
   protected axi_trans#(AW,DW) trans;
   
   // Local variables
                                     
   bit has_checks  ; // global checkers enable
   bit has_coverage; // global coverage enable
   
   
 
   `uvm_component_utils_begin(axi_monitor #(AW,DW))
      `uvm_field_int(has_checks, UVM_ALL_ON)
      `uvm_field_int(has_coverage, UVM_ALL_ON)
   `uvm_component_utils_end
   

   function new(string name, uvm_component parent);
      super.new(name,parent);
      item_collected_port = new("item_collected_port",this);
      // get `has_coverage from db
      uvm_config_db#(int)::get(this, "", "has_coverage", has_coverage);
      // get `has_checks from db
      uvm_config_db#(int)::get(this, "", "has_checks", has_checks);
      
      if (has_coverage) 
      begin

      end
   endfunction:new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      //get virtual interface
      if(!uvm_config_db#(virtual axi_if #(AW,DW))::get(this,"","axi_vif", vif)) begin
         `uvm_fatal(get_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})       
      end
   endfunction:build_phase

   task run_phase(uvm_phase phase);
      // Go over the initial reset
      if (vif.aresetn === 1'b1) @(negedge vif.aresetn);
      @(posedge vif.aresetn);
      // Start monitoring tasks
      fork
       // collect_transactions();          
        //COUNTERS
        
        //COVERAGE
        
        //CHECKERS    
        
      join_none
   endtask:run_phase
   
   // monitor all transactions
   task collect_transactions();
      forever begin
         // Wait for SETUP phase
         // `uvm_info(get_name(), $sformatf("AXI Monitor has started to collect a transfer"), UVM_LOW)
         monitor();
        //@(posedge vif.hclk);
      end
   endtask: collect_transactions
 
   task monitor();
     trans = new;

   endtask: monitor
 

   // Task which monitors HW resets in the middle of the simulation
   task monitor_hw_reset();
      // Go over the initial reset
      @(negedge vif.aresetn);
      forever begin
         @(negedge vif.aresetn);
        // -> axi_reset_cov_e;
      end
   endtask
   
   // Task that assigns the has_checks to the bit in the interface
   task update_has_checks();
      // initial value
      vif.has_checks = has_checks;
      forever begin
         @(has_checks);
         vif.has_checks = has_checks;
      end
   endtask
   
      // UVM report_phase
   function void report_phase(uvm_phase phase);
     
   endfunction
   

//************************************************************ PROTOCOL CHECKERS ************************************************

endclass:axi_monitor

`endif