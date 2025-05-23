//------------------------------------
// File name   : axi_driver.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_DRIVER_SV
`define AXI_DRIVER_SV


class axi_driver #(AW=32,DW=32) extends uvm_driver #(axi_trans #(AW,DW));
   //MASTER or SLAVE
   axi_agent_kind_t agent_kind;

   //register with the factory 
   `uvm_component_utils(axi_driver#(AW,DW))

   //axi interface
   virtual interface axi_if #(AW,DW) vif;

   function new(string name,uvm_component parent = null);
     super.new(name,parent);
   endfunction:new

   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     //get virtual interface
     if(!uvm_config_db#(virtual axi_if #(AW,DW))::get(this,"","axi_vif", vif)) begin
        `uvm_fatal(get_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})
     end
   endfunction:build_phase

   task run_phase(uvm_phase phase);
     super.run_phase(phase);
     drive_reset_values();  //drive reset values
     // Go over initial reset
     @(negedge vif.aresetn);
     forever
     begin
        while($isunknown(vif.aresetn) || vif.aresetn === 1'b0) //reset is x, z or 0
        begin
           drive_reset_values(); //drive reset values
           @(vif.mst_cb);
        end
        seq_item_port.get_next_item(req); //get item from sequencer
        drive_axi_trans(req);
        seq_item_port.item_done(); //signal the sequencer it's ok to send the next item
     end
   endtask:run_phase

   //idle values for driven signals
   task drive_reset_values();
     case (agent_kind)
       AXI_MASTER: begin
           // WRITE ADDRESS CHANNEL
           vif.mst_cb.awvalid <=  'b0;
           vif.mst_cb.awid    <=  'b0;
           vif.mst_cb.awaddr  <=  'b0;
           vif.mst_cb.awlen   <=  'b0;
           vif.mst_cb.awsize  <=  'b0;
           vif.mst_cb.awburst <=  'b0;
           
           // WRITE DATA CHANNEL
           vif.mst_cb.wvalid  <=  'b0;
           vif.mst_cb.wdata   <=  'b0;
           vif.mst_cb.wstrb   <=  'b0;
           vif.mst_cb.wlast   <=  'b0;
           
           // WRITE RESPONSE CHANNEL
           vif.mst_cb.bready  <=  'b0;
           
           // READ ADDRESS CHANNEL
           vif.mst_cb.arvalid <=  'b0;
           vif.mst_cb.arid    <=  'b0;
           vif.mst_cb.araddr  <=  'b0;
           vif.mst_cb.arlen   <=  'b0;
           vif.mst_cb.arsize  <=  'b0;
           vif.mst_cb.arburst <=  'b0;
           
           // READ DATA CHANNEL
           vif.mst_cb.rready  <=  'b0;
       end
       AXI_SLAVE: begin
          // WRITE ADDRESS CHANNEL
          vif.slv_cb.awready  <=  'b0;
          
          // WRITE DATA CHANNEL
          vif.slv_cb.wready   <=  'b0;
          
          // WRITE RESPONSE CHANNEL
          vif.slv_cb.bvalid   <=  'b0;
          vif.slv_cb.bid      <=  'h0;
          
          // READ ADDRESS CHANNEL
          vif.slv_cb.arready  <=  'b0;
          
          // READ DATA CHANNEL
          vif.slv_cb.rvalid   <=  'b0;
          vif.slv_cb.rid      <=  'b0;
          vif.slv_cb.rdata    <=  'b0;
          vif.slv_cb.rlast    <=  'b0;
          vif.slv_cb.rresp    <=  'b0;
       end
     endcase
   endtask:drive_reset_values

   
   //drive AXI transaction
task drive_axi_trans(axi_trans #(AW,DW) trans);
      case (agent_kind)
         AXI_MASTER:
         begin
            
         end //MASTER
         
         
      AXI_SLAVE:
         begin
         
         end //SLAVE
      endcase  
   endtask: drive_axi_trans
endclass:axi_driver
`endif 