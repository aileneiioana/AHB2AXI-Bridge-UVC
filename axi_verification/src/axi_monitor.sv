//------------------------------------
// File name   : axi_monitor.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_MON_SV
`define AXI_MON_SV
`include "axi_agent_config.sv"

class axi_monitor #(AW=32,DW=32) extends uvm_monitor;

   //analysis port for axi transaction
   uvm_analysis_port #(axi_trans#(AW,DW)) item_collected_port;

   //axi interface
   virtual axi_if #(AW,DW) vif;

   //collected transaction 
   protected axi_trans#(AW,DW) trans;
   
   // for write channels
   axi_trans#(AW,DW) write_address_items [$];// to communicate between address channel and data channel
   axi_trans#(AW,DW) write_items [$];        // to communicate between data channel and bresp channel
   // for read channels
   axi_trans#(AW,DW) read_items  [$];        // to communicate between address channel and data channel
   
   axi_agent_config config_params = new;     
   
   // Local variables                              
   bit has_checks  ; // global checkers enable
   bit has_coverage; // global coverage enable
   
   // queue of data for read interleaving associative array
   typedef bit [DW-1:0] int_da [$];       // type for a queue of queues for read data
   typedef bit [   1:0] int_re [$];       // type for a queue of queues for read resp
   
    int unsigned      delay_between_waddr          ; // delay between awvalid&awready and awvalid
    int unsigned      delay_between_raddr          ; // delay between arvalid&arready and arvalid
    int unsigned      delay_between_wdata          ; // delay between wvalid&wready&wlast and wvalid
    int unsigned      delay_between_waddr_wdata    ; // delay between awvalid&awready and wvalid
    int unsigned      delay_between_raddr_rdata    ; // delay between arvalid&arready and rvalid
    int unsigned      delay_between_waddr_bresp    ; // delay between awvalid&awready and balid
    int unsigned      delay_between_raddr_rresp    ; // delay between arvalid&arready and rlast
    int unsigned      delay_between_arvalid        ; // delay between 2 arvalid
    int unsigned      delay_between_awvalid        ; // delay between 2 awvalid
    int unsigned      delay_between_rvalid         ; // delay between 2 rvalid
    int unsigned      delay_between_bresp          ; // delay between 2 bvalid
    int unsigned      delay_between_wvalid_wready  ; // delay between wvalid and wready
    int unsigned      delay_between_rvalid_rready  ; // delay between rvalid and rready
    int unsigned      delay_between_bvalid_bready  ; // delay between bvalid and bready
    int unsigned      delay_between_awvalid_awready; // delay between awvalid and awready
    int unsigned      delay_between_arvalid_arready; // delay between arvalid and arready
    
    //trigger events for covergroups
    event axi_signal_cov_e;
    event axi_delay_cov_e;
    
    //signals that indicated that at least once this happened 
    bit write_outstanding_covered      = 0; 
    bit read_outstanding_covered       = 0;
    bit write_out_of_order_covered     = 0;
    bit read_out_of_order_covered      = 0;
    bit write_in_order_covered         = 0;
    bit read_in_order_covered          = 0;
    bit read_data_interleaving_covered = 0;
    
    covergroup transfer_cov @(vif.mon_cb);
       write_outstanding_covered_sig      :       coverpoint write_outstanding_covered;
       read_outstanding_covered_sig       :       coverpoint read_outstanding_covered;
       write_out_of_order_covered_sig     :       coverpoint write_out_of_order_covered;
       read_out_of_order_covered_sig      :       coverpoint read_out_of_order_covered;
       write_in_order_covered_sig         :       coverpoint write_in_order_covered;
       read_in_order_covered_sig          :       coverpoint read_in_order_covered;
       read_data_interleaving_covered_sig :       coverpoint read_data_interleaving_covered;
    endgroup
    
    covergroup axi_signal_cov @axi_signal_cov_e;
      awid_sig:       coverpoint vif.awid      ;
      awvaid_sig:     coverpoint vif.awvalid   ;
      awready_sig:    coverpoint vif.awready   ;
      arid_sig:       coverpoint vif.arid      ;
      arvaid_sig:     coverpoint vif.arvalid   ;
      arready_sig:    coverpoint vif.arready   ;
      wvaid_sig:      coverpoint vif.wvalid    ;
      wready_sig:     coverpoint vif.wready    ;
      wlast_sig:      coverpoint vif.wlast     ;
      rid_sig:        coverpoint vif.rid       ;
      rready_sig:     coverpoint vif.rready    ;
      rvaid_sig:      coverpoint vif.rvalid     ;
      rlast_sig:      coverpoint vif.rlast     ;
      bid_sig:        coverpoint vif.bid       ;
      bvaid_sig:      coverpoint vif.bvalid    ;
      bready_sig:     coverpoint vif.bready    ;
      awlen_sig:      coverpoint vif.awlen     ;
      arlen_sig:      coverpoint vif.awlen     ;
      bresp_sig:      coverpoint vif.bresp  { 
                                              bins AXI_OKAY    = {'b000};
                                              bins AXI_EXOKAY  = {'b001};
                                              bins AXI_SLVERR  = {'b010};
                                              bins AXI_DECERR  = {'b011};
                                            }
                                            
      rresp_sig:      coverpoint vif.rresp  { 
                                              bins AXI_OKAY    = {'b000};
                                              bins AXI_EXOKAY  = {'b001};
                                              bins AXI_SLVERR  = {'b010};
                                              bins AXI_DECERR  = {'b011};
                                            }
      
      awburst_sig:     coverpoint vif.awburst { 
                                              bins FIXED = {'b000};
                                              bins INCR  = {'b001};
                                              bins WRAP  = {'b010};
                                            }
                                            
      arburst_sig:     coverpoint vif.arburst { 
                                              bins FIXED = {'b000};
                                              bins INCR  = {'b001};
                                              bins WRAP  = {'b010};
                                            }
      awsize_sig:      coverpoint vif.awsize { 
                                             bins BYTE  = {'b000};
                                             bins HWROD = {'b001};
                                             bins WORD  = {'b010};
                                           }
      arsize_sig:      coverpoint vif.arsize { 
                                             bins BYTE  = {'b000};
                                             bins HWROD = {'b001};
                                             bins WORD  = {'b010};
                                           }
      wstrobe_sig:    coverpoint vif.wstrb { 
                                                bins not_single_tr    = {'b1111};
                                                bins single_tr_byte1  = {'b0001};
                                                bins single_tr_byte2  = {'b0010};
                                                bins single_tr_byte3  = {'b0100};
                                                bins single_tr_byte4  = {'b1000};
                                                bins single_tr_hword1 = {'b0011};
                                                bins single_tr_hword2 = {'b1100};
                                                bins single_tr_word   = {'b1111};
                                              }
      awvalid_awready_cp:       cross awvaid_sig, awready_sig;
      arvalid_arready_cp:       cross arvaid_sig, arready_sig;
      wvalid_wready_cp:         cross wvaid_sig,  wready_sig;
      wvalid_wready_wlast_cp:   cross wvaid_sig,  wready_sig, wlast_sig{
                                                  ignore_bins xy1 = binsof(wvaid_sig)  intersect {0};
                                                  ignore_bins xy2 = binsof(wready_sig) intersect {0};
                                                  ignore_bins xy3 = binsof(wlast_sig)  intersect {0};
                                                 }
      rvalid_rready_cp:         cross rvaid_sig,  rready_sig;
      rvalid_rready_rlast_cp:   cross rvaid_sig,  rready_sig, rlast_sig{
                                                  ignore_bins xy1 = binsof(rvaid_sig)  intersect {0};
                                                  ignore_bins xy2 = binsof(rready_sig) intersect {0};
                                                  ignore_bins xy3 = binsof(rlast_sig)  intersect {0};
                                                 }
      rready_rresp_cp:          cross rready_sig, rresp_sig{
                                                  ignore_bins xy1 = binsof(rready_sig)  intersect {0};
                                                 }
      bvalid_bready_cp:         cross bvaid_sig,  bready_sig;
      bready_bresp_cp:          cross bready_sig, bresp_sig{
                                                  ignore_bins xy1 = binsof(bready_sig)  intersect {0};
                                                 }
      axi_cross_write_transfer_cp: cross awsize_sig, awburst_sig;
      axi_cross_read_transfer_cp:  cross arsize_sig, arburst_sig;
   endgroup
   
   covergroup axi_delay_cov @(axi_delay_cov_e);
     delay_between_waddr_c : coverpoint delay_between_waddr{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_raddr_c : coverpoint delay_between_raddr{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_waddr_wdata_c : coverpoint delay_between_waddr_wdata{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_waddr_bresp_c : coverpoint delay_between_waddr_bresp{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_raddr_rdata_c : coverpoint delay_between_raddr_rdata{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_raddr_rresp_c :  coverpoint delay_between_raddr_rresp{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_bresp_c :        coverpoint delay_between_bresp{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_arvalid_c :      coverpoint delay_between_arvalid{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_awvalid_c :      coverpoint delay_between_awvalid{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
     delay_between_rvalid_c :      coverpoint delay_between_rvalid{
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                   }
     delay_between_arvalid_arready_c: coverpoint delay_between_arvalid_arready{
                                      bins zero = {0};
                                      bins one = {1};
                                      bins short= {[ 1: 5]};
                                      bins long = {[11:19]};
                                      }   
     delay_between_awvalid_awready_c: coverpoint delay_between_awvalid_awready{
                                      bins zero = {0};
                                      bins one = {1};
                                      bins short= {[ 1: 5]};
                                      bins long = {[11:19]};
                                      }   
     delay_between_rvalid_rready_c: coverpoint delay_between_rvalid_rready{
                                      bins zero = {0};
                                      bins one = {1};
                                      bins short= {[ 1: 5]};
                                      bins long = {[11:19]};
                                      }   
     delay_between_wvalid_wready_c: coverpoint delay_between_wvalid_wready{
                                      bins zero = {0};
                                      bins one = {1};
                                      bins short= {[ 1: 5]};
                                      bins long = {[11:19]};
                                      }   
     delay_between_bvalid_bready_c: coverpoint delay_between_bvalid_bready{
                                      bins zero = {0};
                                      bins one = {1};
                                      bins short= {[ 1: 5]};
                                      bins long = {[11:19]};
                                      }   
   endgroup
   
   covergroup wdata_toggle_cov with function sample_wdata(bit[DW-1:0] data, int pos);
     toggle_wdata : coverpoint data[pos] {  
                                            bins zeroone = (0 => 1);
                                            bins onezero = (1 => 0);
                                          }
   endgroup

   function void sample_wdata(bit[DW-1:0] data);
      for(int i = 0; i < DW; i++) begin
        wdata_toggle_cov.sample(data, i);
      end
   endfunction
   
    covergroup rdata_toggle_cov with function sample_rdata(bit[DW-1:0] data, int pos);
     toggle_rdata : coverpoint data[pos] {  
                                            bins zeroone = (0 => 1);
                                            bins onezero = (1 => 0);
                                          }
   endgroup

   function void sample_rdata(bit[DW-1:0] data);
      for(int i = 0; i < DW; i++) begin
        rdata_toggle_cov.sample(data, i);
      end
   endfunction
   
    covergroup raddr_toggle_cov with function sample_raddr(bit[DW-1:0] data, int pos);
     toggle_raddr : coverpoint data[pos] {  
                                            bins zeroone = (0 => 1);
                                            bins onezero = (1 => 0);
                                          }
   endgroup

   function void sample_raddr(bit[DW-1:0] data);
      for(int i = 0; i < DW; i++) begin
        raddr_toggle_cov.sample(data, i);
      end
   endfunction
   
   covergroup waddr_toggle_cov with function sample_waddr(bit[DW-1:0] data, int pos);
     toggle_waddr : coverpoint data[pos] {  
                                            bins zeroone = (0 => 1);
                                            bins onezero = (1 => 0);
                                          }
   endgroup

   function void sample_waddr(bit[DW-1:0] data);
      for(int i = 0; i < DW; i++) begin
        waddr_toggle_cov.sample(data, i);
      end
   endfunction
   
   int unsigned       number_of_write_transfers_outstanding; //from config
   int unsigned       number_of_read_transfers_outstanding;
   
   bit outstanding;

   
   `uvm_component_utils_begin(axi_monitor #(AW,DW))
      `uvm_field_int(has_checks, UVM_ALL_ON)
      `uvm_field_int(has_coverage, UVM_ALL_ON)
      `uvm_field_int(number_of_write_transfers_outstanding, UVM_ALL_ON)
      `uvm_field_int(number_of_read_transfers_outstanding, UVM_ALL_ON)
      `uvm_field_int(outstanding, UVM_ALL_ON)
   `uvm_component_utils_end
   
   `uvm_register_cb(axi_monitor, axi_callback)

   function new(string name, uvm_component parent);
      super.new(name,parent);
      item_collected_port = new("item_collected_port",this);
      // get `has_coverage from db
      uvm_config_db#(int)::get(this, "", "has_coverage", has_coverage);
      // get `has_checks from db
      uvm_config_db#(int)::get(this, "", "has_checks", has_checks);
      
       if (has_coverage) 
       begin
        axi_signal_cov   = new;
        axi_delay_cov    = new;
        wdata_toggle_cov = new;
        rdata_toggle_cov = new;
        waddr_toggle_cov = new;
        raddr_toggle_cov = new;
        transfer_cov     = new;
       end
   endfunction:new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      //get virtual interface
      if(!uvm_config_db#(virtual axi_if #(AW,DW))::get(this,"","axi_vif", vif)) begin
         `uvm_fatal(get_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"
         })          
      end
   endfunction:build_phase

   task run_phase(uvm_phase phase);
      // Go over the initial reset
      if (vif.aresetn === 1'b1) @(negedge vif.aresetn);
      @(posedge vif.aresetn);
      // Start monitoring tasks
     //`uvm_info(get_name(), $sformatf("AXI Monitor has started"), UVM_LOW)
      fork
      //monitor channels
        write_address();
        write_data();
        write_response();
        read_address();
        read_data();
      //update has checks to axi_if
        update_has_checks();
      //monitor all delays
        monitor_delays();
      //coverage
        axi_signal_toggle();
      join_none
   endtask:run_phase
   
   //AW CHANNEL
  task  write_address(); 
    axi_trans item;
    forever begin
      if(vif.mon_cb.awvalid && vif.mon_cb.awready)begin
        item = new;
        item.axi_start_addr = vif.mon_cb.awaddr;
        this.sample_waddr(vif.mon_cb.awaddr);
        item.axi_op_type    = AXI_WRITE;
        item.axi_size_type  = vif.mon_cb.awsize;
        item.axi_burst_type = vif.mon_cb.awburst;
        item.axi_length     = vif.mon_cb.awlen;
        item.axi_id         = vif.mon_cb.awid;
        item.appearance_time=$time;
        write_address_items.push_back(item); //for data channel
      // `uvm_info(get_name(), $sformatf("The AXI MONITOR write address\n %h", item.axi_start_addr), UVM_LOW)
      end//if awvalid & awready
      @(vif.mon_cb);
     end  // forever
  endtask : write_address 

  // W CHANNEL
  task write_data();

    axi_trans     item = new;
    bit [DW-1:0]  w_q[$];
    bit [3:0]     w_s;
    
    item = null;
    
    forever begin
      @(vif.mon_cb iff (vif.mon_cb.wready && vif.mon_cb.wvalid));
      w_q.push_back(vif.mon_cb.wdata); //collects wdata
      while(~vif.mon_cb.wlast)
      begin
        @(vif.mon_cb iff (vif.mon_cb.wready && vif.mon_cb.wvalid));
        w_q.push_back(vif.mon_cb.wdata);
        this.sample_wdata(vif.mon_cb.wdata);
        w_s = vif.mon_cb.wstrb;
      end
      item = write_address_items.pop_front(); //item for address channel and completes it with data collected
      //`uvm_info(get_name(), $sformatf("The  write data %d \n %s", item.axi_id, item.sprint()), UVM_LOW)
      item.axi_data    = w_q;
      item.axi_wstrobe = vif.mon_cb.wstrb;
      // `uvm_info(get_name(), $sformatf("The AXI MONITOR write data %d \n %s", item.axi_id, item.sprint()), UVM_LOW)
       write_items.push_back(item); //for WRESPONSE CHANNEL
       if(write_items.size == number_of_write_transfers_outstanding) begin 
        write_outstanding_covered = 1;
     //  `uvm_info(get_name(), $sformatf("write_outstanding_covered\n "), UVM_LOW)
       end
       else if(write_items.size > number_of_write_transfers_outstanding) begin //nr items without response 
        uvm_report_error("Max WRITE Outstanding ERROR" , "There are more write outstanding trasnfers than max nr configured" );
       end
       // `uvm_info(get_name(), $sformatf("The  write_items write data %d \n %s", item.axi_id, item.sprint()), UVM_LOW)
        w_q.delete();
        w_s =0;
    end//forever
 endtask : write_data
 
   function axi_trans#(AW,DW) search_write_item_by_id(bit[3:0] id);
    foreach(write_items[i])
    // if(read_items[i] != null)
      if(write_items[i].axi_id == id) return write_items[i];

  endfunction

  //WRESPONSE CHANNEL
  task write_response();
    axi_trans item = new;
    int position=0 ;
    item = null;
   
    forever begin
        @(vif.mon_cb iff (vif.mon_cb.bvalid && vif.mon_cb.bready));
        //item = write_items.pop_front();
        if (search_write_item_by_id(vif.mon_cb.bid))begin //search item in queue from write data channel
        item = search_write_item_by_id(vif.mon_cb.bid);
        item.axi_resp = vif.mon_cb.bresp; // completes it with resp
        for(int i=0;i<write_items.size();i++)
          if(write_items[i] == item)  position = i;
        if(position != 0 )begin
          write_out_of_order_covered = 1;
         // `uvm_info(get_name(), $sformatf("write_out_of_order_covered\n "), UVM_LOW)
        end
        else if(position == 0 )begin
          write_in_order_covered = 1;
        //  `uvm_info(get_name(), $sformatf("write_in_order_covered\n "), UVM_LOW)
        end
        write_items.delete(position);
        item_collected_port.write(item); //send item to scoreboard
      //`uvm_info(get_name(), $sformatf("The AXI MONITOR write resp\n %s", item.sprint()), UVM_LOW)
        `uvm_do_callbacks(axi_monitor,axi_callback,counts_finished_writes ()); //callback function which counts items with resp to know when to close the test
        item = null;
        end
    end  // forever
  endtask : write_response

  function int search_read_item_not_zero();
   int count = 0;
    foreach(read_items[i])
    // if(read_items[i] != null)
      if(read_items[i]!=null) count++;
    return count;
  endfunction
  
  bit [3:0] read_ids_order [$];   //for knowing id read order on bus
  bit [4:0] rlen_queue     [$];  // arlen collected on arvalid&arready
  bit [4:0] pending_ids [$][$];  // used for when the same id appear on bus and the transfer with the same id is not ready
    
  // AR CHANNEL
  task read_address();
   axi_trans item;
   for (int i=0;i<16;i++) begin
    read_items[i] = null;
    rlen_queue[i] = 0;
    pending_ids[i] = {};
   end
    forever begin
      if(vif.mon_cb.arvalid && vif.mon_cb.arready)begin
         if(rlen_queue[vif.mon_cb.arid]) pending_ids[vif.mon_cb.arid].push_back(vif.mon_cb.arlen +1);
         else rlen_queue[vif.mon_cb.arid] = vif.mon_cb.arlen +1;
        item = new;
        item.axi_start_addr     = vif.mon_cb.araddr;
        this.sample_raddr(vif.mon_cb.araddr);
        item.axi_op_type        = AXI_READ;
        item.axi_size_type      = vif.mon_cb.arsize;
        item.axi_burst_type     = vif.mon_cb.arburst;
        item.axi_length         = vif.mon_cb.arlen;
        item.axi_id             = vif.mon_cb.arid;
        item.appearance_time    = $time;
        read_items[item.axi_id] = item; //for data channel
        read_ids_order.push_back(vif.mon_cb.arid);
        if(search_read_item_not_zero() == number_of_read_transfers_outstanding) begin 
          read_outstanding_covered = 1; 
         // `uvm_info(get_name(), $sformatf("read_outstanding_covered\n "), UVM_LOW)
        end
        if(search_read_item_not_zero() > number_of_read_transfers_outstanding) begin 
          uvm_report_error("Max Read Outstanding ERROR" , "There are more read outstanding trasnfers than max nr configured" );
        end
        //`uvm_info(get_name(), $sformatf("The AXI MONITOR read address\n %h", item.axi_start_addr), UVM_LOW)
        end//if arvalid & arready
      @(vif.mon_cb);
    end  // forever
  endtask : read_address 

  function axi_trans#(AW,DW) search_read_item_by_id(bit[3:0] id);
    foreach(read_items[i])
    // if(read_items[i] != null)
      if(read_items[i].axi_id == id) return read_items[i];
      else 
        return null;
  endfunction
  
  function axi_trans_resp_t search_error_rresp(bit[1:0] w_r[$]);
    foreach(w_r[i])
      if(w_r[i] >1) return w_r[i];
    return AXI_EXOKAY;
  endfunction
  
// R CHANNEL
  task read_data();   
    int i, position = -1;
    axi_trans    item = new;
    int_da       w_q [bit[3:0]];
    int_re       w_r [bit[3:0]];
    item = null;

    forever begin
      @(vif.mon_cb iff (vif.mon_cb.rready && vif.mon_cb.rvalid));
      if(read_ids_order[0] != vif.mon_cb.rid) read_data_interleaving_covered = 1;
      w_q [vif.mon_cb.rid].push_back(vif.mon_cb.rdata); //collects rdata and puts in the rigth place by id
      this.sample_rdata(vif.mon_cb.rdata);
      rlen_queue[vif.mon_cb.rid]--;
      if(vif.mon_cb.rresp) 
        w_r [vif.mon_cb.rid].push_back(vif.mon_cb.rresp);  
  
      if(vif.mon_cb.rlast) begin //if last data collects it and completes the addres item
        if(rlen_queue[vif.mon_cb.rid] != 0) uvm_report_error("RLAST ERROR" , "There are more data to sent, this is not the last" );
        item =  read_items[vif.mon_cb.rid];
        foreach(read_ids_order[i]) 
          if(read_ids_order[i] == vif.mon_cb.rid) begin
            position=i;
            continue;
          end
        if(position) begin 
          read_out_of_order_covered = 1;
         // `uvm_info(get_name(), $sformatf("read_out_of_order_covered\n "), UVM_LOW) 
        end
        else if(position == 0) begin 
          read_in_order_covered = 1;
         // `uvm_info(get_name(), $sformatf("read_in_order_covered\n "), UVM_LOW) 
        end
        read_ids_order.delete(position);
        if(vif.mon_cb.rresp)
        w_r [vif.mon_cb.rid].push_back(vif.mon_cb.rresp);  
        if( w_r [vif.mon_cb.rid].size)
              item.axi_resp = search_error_rresp(w_r [vif.mon_cb.rid]);
        else item.axi_resp = AXI_OKAY;
        item.axi_data = w_q[vif.mon_cb.rid];
        if(rlen_queue[vif.mon_cb.rid] != 0) begin 
           uvm_report_error("ARLEN ERROR" , "ARLEN Calculation ERROR" );
          `uvm_info(get_type_name(), $sformatf("ARLEN Calculation ERROR item.axi_length %d rlen_queue[vif.mon_cb.rid] %d id",item.axi_length, rlen_queue[vif.mon_cb.rid],vif.mon_cb.rid ), UVM_LOW)
        end
        if(pending_ids[vif.mon_cb.rid].size) begin 
          rlen_queue[vif.mon_cb.rid]=pending_ids[vif.mon_cb.rid].pop_front();
         end
     //  `uvm_info(get_name(), $sformatf("The AXI MONITOR read resp\n %s", item.sprint()), UVM_LOW)
        `uvm_do_callbacks(axi_monitor,axi_callback,counts_finished_reads ()); //counts read data items finished to know when to stop the test
        item_collected_port.write(item);
        w_q.delete(vif.mon_cb.rid);
        item = null;
        read_items[vif.mon_cb.rid] = null;
      end
    end//forever
 endtask : read_data
 
 // monitoring all delays
 task monitor_delays();
 
 int unsigned      timestamp_waddr_data [$]     ;  // when awaddr appear
 int unsigned      timestamp_raddr_data [$]     ;  // when araddr appear
 int unsigned      timestamp_raddr_resp [$]     ;  // when rlast appear
 int unsigned      time1 = 0;
 int unsigned      time2 = 0;
 
 for (int i=0;i<16;i++)begin
   timestamp_raddr_data[i] = -1; // unsigned, so 1111111 x32 - a little chance to happen
   timestamp_raddr_resp[i] = -1;
 end
 
fork
  forever begin
  //delay_between_waddr
    if(vif.mon_cb.awready && vif.mon_cb.awvalid) begin 
    time1 = $time;
    timestamp_waddr_data.push_back(time1);
      //`uvm_info(get_name(), $sformatf("abc delay_between_waddr %d", delay_between_waddr), UVM_LOW)
       ->axi_delay_cov_e;
      delay_between_waddr=0; 
    end
    if(!vif.mon_cb.awready || !vif.mon_cb.awvalid) begin
      delay_between_waddr++;
     end
   @(vif.mon_cb);
  end
  
  //delay_between_raddr
   forever begin
    if(vif.mon_cb.arready && vif.mon_cb.arvalid) begin 
      time2 = $time;
      //if(timestamp_raddr_data[vif.mon_cb.arid] != -1)
        timestamp_raddr_data[vif.mon_cb.arid] = time2 ;
      //if(timestamp_raddr_resp[vif.mon_cb.arid] != -1 )
        timestamp_raddr_resp[vif.mon_cb.arid] = time2 ;
     // `uvm_info(get_name(), $sformatf("def delay_between_raddr %d", delay_between_raddr), UVM_LOW)
       ->axi_delay_cov_e;
      delay_between_raddr=0; 
    end
    if(!vif.mon_cb.arready || !vif.mon_cb.arvalid) begin
      delay_between_raddr++;
     end
   @(vif.mon_cb);
  end
  
  //delay_between_wdata
   forever begin
     delay_between_wdata = 0;
     while (!vif.mon_cb.wvalid) 
     begin 
       @(vif.mon_cb);
       delay_between_wdata++;
     end
     wait(vif.mon_cb.wvalid); 
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
   // if(vif.mon_cb.wvalid && delay_between_wdata) begin 
      //`uvm_info(get_name(), $sformatf("ghi delay_between_wdata %d", delay_between_wdata), UVM_LOW)  
     
     //end
   end
   
   //delay_between_bresp
    forever begin
     delay_between_bresp = 0;
     while (!vif.mon_cb.bvalid) 
     begin 
       @(vif.mon_cb);
       delay_between_bresp++;
     end
     wait(vif.mon_cb.bvalid);
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
     //if(vif.mon_cb.bvalid && delay_between_bresp) begin 
      //`uvm_info(get_name(), $sformatf("efg delay_between_bresp %d", delay_between_bresp), UVM_LOW)  
     //end
   end
   
   //delay_between_rvalid
    forever begin
     delay_between_rvalid = 0;
     while (!vif.mon_cb.rvalid) 
     begin 
       @(vif.mon_cb);
       delay_between_rvalid++;
     end
     wait(vif.mon_cb.rvalid); 
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
     //if(vif.mon_cb.rvalid && delay_between_rvalid) begin 
      //`uvm_info(get_name(), $sformatf("jkl delay_between_rvalid %d", delay_between_rvalid), UVM_LOW)  
     //end
   end
   
   //delay_between_awvalid
   forever begin
     delay_between_awvalid = 0;
     while (!vif.mon_cb.awvalid) 
     begin 
       @(vif.mon_cb);
       delay_between_awvalid++;
     end
     wait(vif.mon_cb.awvalid); 
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
     //if(vif.mon_cb.awvalid && delay_between_awvalid) begin 
      //`uvm_info(get_name(), $sformatf("jkl delay_between_awvalid %d", delay_between_awvalid), UVM_LOW)  
    // end
   end
   
   //delay_between_arvalid
   forever begin
     delay_between_arvalid = 0;
     while (!vif.mon_cb.arvalid) 
     begin 
       @(vif.mon_cb);
       delay_between_arvalid++;
     end
     wait(vif.mon_cb.arvalid); 
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
     //if(vif.mon_cb.arvalid && delay_between_arvalid) begin 
      //`uvm_info(get_name(), $sformatf("jkl delay_between_arvalid %d", delay_between_arvalid), UVM_LOW)  
    // end
   end
   
   //delay_between_wvalid_wready
    forever begin
     delay_between_wvalid_wready = 0;
     while (vif.mon_cb.wvalid && !vif.mon_cb.wready) 
     begin 
       @(vif.mon_cb);
       delay_between_wvalid_wready++;
     end
     wait(vif.mon_cb.wvalid && vif.mon_cb.wready);
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
     //if(delay_between_wvalid_wready) begin 
      //`uvm_info(get_name(), $sformatf("rqs delay_between_wvalid_wready %d", delay_between_wvalid_wready), UVM_LOW)  
   // end
   end
   
   //delay_between_rvalid_rready
    forever begin
     delay_between_rvalid_rready = 0;
     while (vif.mon_cb.rvalid && !vif.mon_cb.rready) 
     begin 
       @(vif.mon_cb);
       delay_between_rvalid_rready++;
     end
     wait(vif.mon_cb.rvalid && vif.mon_cb.rready);
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
    end
   
   //delay_between_bvalid_bready
    forever begin
     delay_between_bvalid_bready = 0;
     while (vif.mon_cb.bvalid && !vif.mon_cb.bready) 
     begin 
       @(vif.mon_cb);
       delay_between_bvalid_bready++;
     end
     wait(vif.mon_cb.bvalid && vif.mon_cb.bready);
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
   end
   
   //delay_between_arvalid_arready
    forever begin
     delay_between_arvalid_arready = 0;
     while (vif.mon_cb.arvalid && !vif.mon_cb.arready) 
     begin 
       @(vif.mon_cb);
       delay_between_arvalid_arready++;
     end
     wait(vif.mon_cb.arvalid && vif.mon_cb.arready);
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
   end
   
   //delay_between_arvalid_arready
    forever begin
     delay_between_arvalid_arready = 0;
     while (vif.mon_cb.arvalid && !vif.mon_cb.arready) 
     begin 
       @(vif.mon_cb);
       delay_between_arvalid_arready++;
     end
     wait(vif.mon_cb.arvalid && vif.mon_cb.arready);
     ->axi_delay_cov_e;
     @(vif.mon_cb);        
   end
   
   //delay_between_waddr_wdata
   forever begin
     delay_between_waddr_wdata = 0;
     @(vif.mon_cb iff vif.mon_cb.wvalid);
       delay_between_waddr_wdata = ($time - timestamp_waddr_data.pop_front())/ (config_params.period)  ;
      //`uvm_info(get_name(), $sformatf("xyz delay_between_waddr_wdata %d %d", $time, delay_between_waddr_wdata), UVM_LOW)
        ->axi_delay_cov_e;
      @(vif.mon_cb iff vif.mon_cb.wvalid && vif.mon_cb.wready && vif.mon_cb.wlast);
      timestamp_waddr_data.push_back($time);
     delay_between_waddr_wdata = 0;
   end
   
   //delay_between_raddr_rdata
    forever begin
     delay_between_raddr_rdata = 0;
     @(vif.mon_cb iff vif.mon_cb.rvalid);
       if(timestamp_raddr_data[vif.mon_cb.rid] != -1)begin
       delay_between_raddr_rdata = ($time - timestamp_raddr_data[vif.mon_cb.rid])/ (config_params.period)  ;
      //`uvm_info(get_name(), $sformatf("xyzt delay_between_raddr_rdata %d %d", $time, delay_between_raddr_rdata), UVM_LOW)
       ->axi_delay_cov_e;
       end
      @(vif.mon_cb);
     delay_between_raddr_rdata = 0;
     timestamp_raddr_data[vif.mon_cb.rid] = -1;
   end
   
   //delay_between_raddr_rresp
   forever begin
     delay_between_raddr_rresp = 0;
     @(vif.mon_cb iff (vif.mon_cb.rvalid && vif.mon_cb.rready && vif.mon_cb.rlast));
       if(timestamp_raddr_resp[vif.mon_cb.rid] != -1)begin
        delay_between_raddr_rresp = ($time - timestamp_raddr_resp[vif.mon_cb.rid])/ (config_params.period)  ;
       // `uvm_info(get_name(), $sformatf("mno delay_between_raddr_rresp %d %d", $time, delay_between_raddr_rresp), UVM_LOW)
        ->axi_delay_cov_e;
       end
      @(vif.mon_cb);
     delay_between_raddr_rresp = 0;
     timestamp_raddr_resp[vif.mon_cb.rid] = -1;
   end
   
   //delay_between_waddr_bresp
   forever begin
     delay_between_waddr_bresp = 0;
     @(vif.mon_cb iff (vif.mon_cb.bvalid && vif.mon_cb.bready));
       delay_between_waddr_bresp = ($time - timestamp_waddr_data.pop_front())/ (config_params.period)  ;
      //`uvm_info(get_name(), $sformatf("mnop delay_between_waddr_bresp %d %d", $time, delay_between_waddr_bresp), UVM_LOW)
      ->axi_delay_cov_e;
      @(vif.mon_cb);
     delay_between_waddr_bresp = 0;
   end
  join_none
 endtask: monitor_delays
  
 
    // Task used in coverage collection
   task axi_signal_toggle();
      forever begin
         @( vif.awvalid or vif.awready or vif.awid  or vif.awlen or vif.awsize or vif.awburst or 
            vif.arvalid or vif.arready or vif.arid  or vif.arlen or vif.arsize or vif.arburst or
            vif.wvalid  or vif.wready  or vif.wlast or vif.wstrb or 
            vif.rvalid  or vif.rready  or vif.rid   or vif.rlast or vif.rresp  or
            vif.bvalid  or vif.bready  or vif.bid   or vif.bresp  );
         -> axi_signal_cov_e;
      end
   endtask

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
      vif.four_kb_enable = config_params.four_kb_boundary_enable;
      forever begin
         @(has_checks);
         vif.has_checks = has_checks;
      end
   endtask
   
   
      // UVM report_phase
   function void report_phase(uvm_phase phase);
    // `uvm_info(get_name(), $sformatf("Monitor Report:  Done \n"), UVM_LOW)
   endfunction

endclass:axi_monitor

`endif