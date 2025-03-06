//------------------------------------
// File name   : ahb_monitor.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_MON_SV
`define AHB_MON_SV


class ahb_monitor #(AW=32,DW=32) extends uvm_monitor;

   //analysis port for ahb transaction
   uvm_analysis_port #(ahb_trans#(AW,DW)) item_collected_port;

   //ahb interface
   virtual ahb_if #(AW,DW) vif;

   //collected transaction 
   protected ahb_trans#(AW,DW) trans;
   protected ahb_trans#(AW,DW) trans1;
   
   // Local variables
   int unsigned transfer_number = 0                    ;    // number of transfers collected
   int unsigned temp_delay                             ;    // variable used for measuring inter packet delay
   int          hready_delay = 0                       ;    // how many cycles hreadyout is 0
   int          BUSY_cycles  = 0                       ;    // how many BUSY cycles are in a transaction
   int          number_of_addresses_per_trans          ;    // value of how many addresses should be in a transfer (for e.g.: if HBURST is INCR4 number_of_addresses_per_trans will be 4)
                                     
   bit has_checks  ; // global checkers enable
   bit has_coverage; // global coverage enable
   
   bit pending = 0;
   
   //flags for BUSY position coverage
   bit BUSY_after_NONSEQ            = 0;
   bit BUSY_after_BUSY              = 0;
   bit BUSY_after_SEQ               = 0;
   bit BUSY_before_SEQ_and_not_last = 0;
   bit BUSY_before_SEQ_and_last     = 0;
   
   //flags for checkers coverage
   bit seq_transfer_check_sig              = 0;
   bit busy_transfer_check_seq_sig         = 0;
   bit busy_transfer_check_sig             = 0;
   bit idle_transfer_check_sig             = 0;
   bit stable_data_check_sig               = 0;
   bit hburst_transfer_check_4_sig         = 0;
   bit hburst_transfer_check_8_sig         = 0;
   bit hburst_transfer_check_16_sig        = 0;
   bit address_calculated_correctly_INCR4  = 0;
   bit address_calculated_correctly_INCR8  = 0;
   bit address_calculated_correctly_INCR16 = 0;
   bit address_calculated_correctly_WRAP4  = 0;
   bit address_calculated_correctly_WRAP8  = 0;
   bit address_calculated_correctly_WRAP16 = 0;
   
   // Coverage events
   event ahb_signal_cov_e;  // covergroup for all signals
   event ahb_reset_cov_e;   // covergroup to check hreset_n assertion
   event ahb_trans_cov_e;   // covergroup for delay between transfers, delay between hreadyout pulses and busy_cycles
   event ahb_busy_cov_e;    // covergroup for positioning BUSY on different cycles of transfer
   event ahb_checkers_cov_e;// covergroup for checkers 
 
   `uvm_component_utils_begin(ahb_monitor #(AW,DW))
      `uvm_field_int(has_checks, UVM_ALL_ON)
      `uvm_field_int(has_coverage, UVM_ALL_ON)
   `uvm_component_utils_end
   
    `uvm_register_cb(ahb_monitor, ahb_callback)
   
   covergroup ahb_checkers_cov @ahb_checkers_cov_e;
      seq_transfer_check:                         coverpoint seq_transfer_check_sig;
      busy_transfer_check_seq:                    coverpoint busy_transfer_check_seq_sig ;
      busy_transfer_check:                        coverpoint busy_transfer_check_sig;
      idle_transfer_check:                        coverpoint idle_transfer_check_sig;
      stable_data_check:                          coverpoint stable_data_check_sig;
      hburst_transfer_check_4:                    coverpoint hburst_transfer_check_4_sig;
      hburst_transfer_check_8:                    coverpoint hburst_transfer_check_8_sig;
      hburst_transfer_check_16:                   coverpoint hburst_transfer_check_16_sig;
      address_calculated_correctly_INCR4_check:   coverpoint address_calculated_correctly_INCR4;
      address_calculated_correctly_INCR8_check:   coverpoint address_calculated_correctly_INCR8;
      address_calculated_correctly_INCR16_check:  coverpoint address_calculated_correctly_INCR16;
      address_calculated_correctly_WRAP4_check:   coverpoint address_calculated_correctly_WRAP4;
      address_calculated_correctly_WRAP8_check:   coverpoint address_calculated_correctly_WRAP8;
      address_calculated_correctly_WRAP16_check:  coverpoint address_calculated_correctly_WRAP16;
    endgroup
   
    covergroup ahb_busy_cov @ahb_busy_cov_e;
      BUSY_after_NONSEQ_sig:                       coverpoint BUSY_after_NONSEQ;
      BUSY_after_BUSY_sig:                         coverpoint BUSY_after_BUSY;
      BUSY_after_SEQ_sig:                          coverpoint BUSY_after_SEQ;
      BUSY_before_SEQ_and_not_last_sig:            coverpoint BUSY_before_SEQ_and_not_last;
      BUSY_before_SEQ_and_last_sig:                coverpoint BUSY_before_SEQ_and_last;
      op_type_sig:                                 coverpoint vif.hwrite;
      BUSY_after_NONSEQ_cross_op_type:             cross op_type_sig, BUSY_after_NONSEQ_sig;
      BUSY_after_BUSY_cross_op_type:               cross op_type_sig, BUSY_after_BUSY_sig;
      BUSY_after_SEQ_cross_op_type:                cross op_type_sig, BUSY_after_SEQ_sig;
      BUSY_before_SEQ_and_not_last_cross_op_type:  cross op_type_sig, BUSY_before_SEQ_and_not_last_sig;
      BUSY_before_SEQ_and_last_cross_op_type:      cross op_type_sig, BUSY_before_SEQ_and_last_sig;
    endgroup

   covergroup ahb_signal_cov @ahb_signal_cov_e;
      hsel_sig:       coverpoint vif.hsel     ;
      hwrite_sig:     coverpoint vif.hwrite   ;
      hreadyout_sig:  coverpoint vif.hreadyout;
      hresp_sig:      coverpoint vif.hresp    ;
      htrans_sig:     coverpoint vif.mon_cb.htrans   ;
      hburst_sig:     coverpoint vif.hburst { 
                                              bins SINGLE = {'b000};
                                              bins WRAP4  = {'b010};
                                              bins INCR4  = {'b011};
                                              bins WRAP8  = {'b100};
                                              bins INCR8  = {'b101};
                                              bins WRAP16 = {'b110};
                                              bins INCR16 = {'b111};
                                            }
      hsize_sig:      coverpoint vif.hsize { 
                                             bins BYTE  = {'b000};
                                             bins HWROD = {'b001};
                                             bins WORD  = {'b010};
                                           }
      hstrobe_sig:    coverpoint vif.hwstrobe { 
                                                bins not_single_tr    = {'b1111};
                                                bins single_tr_byte1  = {'b0001};
                                                bins single_tr_byte2  = {'b0010};
                                                bins single_tr_byte3  = {'b0100};
                                                bins single_tr_byte4  = {'b1000};
                                                bins single_tr_hword1 = {'b0011};
                                                bins single_tr_hword2 = {'b1100};
                                                bins single_tr_word   = {'b1111};
                                              }
      read_write_with_and_no_err: cross hwrite_sig, hresp_sig;                                        
      all_types:      cross hwrite_sig, hburst_sig, hsize_sig;
   endgroup
   
   // Reset
   covergroup ahb_reset_cov @(ahb_reset_cov_e);
      hreset_sig: coverpoint vif.hreset_n;
   endgroup
   
   covergroup ahb_trans_cov @(ahb_trans_cov_e);
     transaction_delay : coverpoint trans.ahb_trans_delay {
                                    bins b2b = {0};
                                    bins one = {1};
                                    bins short= {[ 1: 5]};
                                    bins long = {[11:19]};
                                    }
    hready_delay : coverpoint trans.ahb_ready_delay {
                                    bins b2b = {0};
                                    bins one = {1};
                                    bins long= {[1:10]};
                                    }
    busy_cycles : coverpoint trans.busy_cycles {
                                    bins no_busy = {0};
                                    bins short_busy= {[ 1: 5]};
                                    bins long_busy = {[11:19]};
                                    }
   endgroup
   
   covergroup hwdata_toggle_cov with function sample_hwdata(bit[DW-1:0] data, int pos);
     toggle_hwdata : coverpoint data[pos] {  
                                            bins zeroone = (0 => 1);
                                            bins onezero = (1 => 0);
                                          }
   endgroup

   function void sample_hwdata(bit[DW-1:0] data);
      for(int i = 0; i < DW; i++) begin
        hwdata_toggle_cov.sample(data, i);
      end
   endfunction
   
   covergroup hrdata_toggle_cov with function sample_hrdata(bit[DW-1:0] data, int pos);
     toggle_hrdata : coverpoint data[pos] {  
                                            bins zeroone = (0 => 1);
                                            bins onezero = (1 => 0);
                                          }
   endgroup

   function void sample_hrdata(bit[DW-1:0] data);
      for(int i = 0; i < DW; i++) begin
        hrdata_toggle_cov.sample(data, i);
      end
   endfunction
 

   function new(string name, uvm_component parent);
      super.new(name,parent);
      item_collected_port = new("item_collected_port",this);
      // get `has_coverage from db
      uvm_config_db#(int)::get(this, "", "has_coverage", has_coverage);
      // get `has_checks from db
      uvm_config_db#(int)::get(this, "", "has_checks", has_checks);
      
      if (has_coverage) 
      begin
         ahb_signal_cov         = new;
         ahb_reset_cov          = new;
         ahb_trans_cov          = new;
         hwdata_toggle_cov      = new;
         hrdata_toggle_cov      = new;
         ahb_busy_cov           = new;
         ahb_checkers_cov       = new;
      end
   endfunction:new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      //get virtual interface
      if(!uvm_config_db#(virtual ahb_if #(AW,DW))::get(this,"","ahb_vif", vif)) begin
         `uvm_fatal(get_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})       
      end
   endfunction:build_phase

   task run_phase(uvm_phase phase);
      // Go over the initial reset
      if (vif.hreset_n === 1'b1) @(negedge vif.hreset_n);
      @(posedge vif.hreset_n);
      // Start monitoring tasks
      fork
        collect_transactions();          
        //COUNTERS
        monitor_BUSY();                 // counts how many BUSY cycles
        monitor_BUSY_position();
        monitor_inter_trans_delay();    // counts cycles between transactions (between hsel = 1)
        monitor_inter_hready_delay();   // counts cycles between hready (how manu cycles hreadyout is 0) 
        //COVERAGE
        ahb_signal_toggle();            // when a signal tooggle => generates the event for signals covergroup
        ahb_busy_toggle();
        ahb_checkers_toggle();
        //CHECKERS    
        update_has_checks();            // assigns the has_checks to the bit in the interface
        seq_transfer_check();           // checks if the control information is identical to the previous transfer when is SEQ transfer type
        busy_transfer_check();          // checks if the control information is identical to the previous transfer when is BUSY transfer type
        idle_transfer_check();          // checks if the control information is identical to the previous transfer when is IDLE transfer type
        stable_data_check();            // checks if hready is LOW then haddr and hwrite and hwdata should remain in the same state until it hready goes HIGH
        hburst_transfer_check();        // hburst generates transfer correctly (check if it generates the number of addresses correctly)
      monitor_hready_low();
      join_none
   endtask:run_phase
   
   
   
   // Task to monitor BUSY cycles
   task monitor_BUSY();
     BUSY_cycles = 0;
     forever begin
        if(vif.mon_cb.htrans == BUSY)
        begin
           BUSY_cycles++;
        end
        else 
        if(vif.mon_cb.htrans == NONSEQ)
        begin
           BUSY_cycles=0;
        end
        @(vif.mon_cb);    
     end
   endtask: monitor_BUSY
   
    // Task to monitor BUSY cycles
   task monitor_hready_low(); 
     forever begin
      @(vif.mon_cb iff vif.mon_cb.hsel);
      forever begin 
        if(vif.mon_cb.hreadyout == 'b0)begin
           `uvm_do_callbacks(ahb_monitor,ahb_callback,counts_number_of_wait_hreadyout); 
        end
        else begin
           `uvm_do_callbacks(ahb_monitor,ahb_callback,zero_number_of_wait_hreadyout); 
        end
        @(vif.mon_cb);    
      end  
     end
   endtask
   
     // Task to monitor BUSY cycles position
   task monitor_BUSY_position();
     forever begin
     if(vif.mon_cb.htrans == NONSEQ && vif.mon_cb.hreadyout)
        begin
           @(vif.mon_cb);   
           if(vif.mon_cb.htrans == BUSY) begin
             BUSY_after_NONSEQ = 1;
             @(vif.mon_cb);
             BUSY_after_NONSEQ = 0;
           end
        end
        if(vif.mon_cb.htrans == SEQ && vif.mon_cb.hreadyout)
        begin
           @(vif.mon_cb);  
           if(vif.mon_cb.htrans == BUSY) begin 
             BUSY_after_SEQ = 1;
             @(vif.mon_cb);
             BUSY_after_SEQ = 0;
           end
        end
        if(vif.mon_cb.htrans == BUSY)
        begin
           @(vif.mon_cb);
           if(vif.mon_cb.htrans == BUSY) begin
             BUSY_after_BUSY = 1;
             @(vif.mon_cb);  
             BUSY_after_BUSY = 0;
           end
           else if(vif.mon_cb.htrans == SEQ && number_of_addresses_per_trans != 2) begin 
             BUSY_before_SEQ_and_not_last = 1;
             @(vif.mon_cb); 
             BUSY_before_SEQ_and_not_last = 0;
           end
           else if(vif.mon_cb.htrans == SEQ && number_of_addresses_per_trans == 2) begin 
             BUSY_before_SEQ_and_last = 1;
             @(vif.mon_cb); 
             BUSY_before_SEQ_and_last = 0;
           end
        end
        @(vif.mon_cb);    
     end
   endtask: monitor_BUSY_position
   
   
   // Task to monitor inter-transactions delay
   task monitor_inter_trans_delay();
     forever begin
         temp_delay = 0;
         // wait for the setup phase
         while ((vif.mon_cb.hsel != 1'b1)|| (vif.mon_cb.hsel ==1'b1 && vif.mon_cb.htrans == IDLE) ) 
         begin 
            @(vif.mon_cb);
            temp_delay++;
         end
         // wait for the transaction done
         wait(vif.mon_cb.hsel == 1'b1 && vif.mon_cb.htrans == NONSEQ);
         @(vif.mon_cb);    
      end
   endtask: monitor_inter_trans_delay
   
   // Task to monitor inter-hready delay
   task monitor_inter_hready_delay();
      forever begin
         while (vif.hreadyout === 1'b0) 
         begin 
            hready_delay++;
            @(vif.mon_cb); 
         end
         wait(vif.hreadyout === 1'b1);
         hready_delay=0;
         @(vif.mon_cb);
     end
   endtask: monitor_inter_hready_delay
 
 
   // monitor all transactions
   task collect_transactions();
      forever begin
         // Wait for SETUP phase
         //wait(vif.mon_cb.hsel === 1'b1 && vif.mon_cb.htrans ==NONSEQ&&vif.mst_cb.hreadyout);
         @(vif.mon_cb iff (vif.mon_cb.hsel && vif.mon_cb.htrans == NONSEQ));
       // `uvm_info(get_name(), $sformatf("AHB Monitor has started to collect a transfer"), UVM_LOW)
         monitor();
        //@(posedge vif.hclk);
      end
   endtask: collect_transactions
   
 
    task monitor();
     trans = new;
    //if(vif.mon_cb.htrans != NONSEQ )  @(vif.mst_cb iff vif.mon_cb.htrans == NONSEQ);
    // when is NONSEQ collects all control signals and assign value for number_of_addresses_per_trans which counts the addresses in transfer
     begin 
     if(pending == 0)begin
            trans.ahb_size_type  = vif.mon_cb.hsize   ;
            trans.ahb_burst_type = vif.mon_cb.hburst  ;
            trans.ahb_wstrobe    = vif.mon_cb.hwstrobe;
            
            if(vif.mon_cb.hburst == INCR4 || vif.mon_cb.hburst== WRAP4) number_of_addresses_per_trans = 4;
            else if(vif.mon_cb.hburst == SINGLE) number_of_addresses_per_trans = 1;
            else if(vif.mon_cb.hburst == INCR8 || vif.mon_cb.hburst== WRAP8) number_of_addresses_per_trans = 8;
            else if(vif.mon_cb.hburst == INCR16 || vif.mon_cb.hburst== WRAP16) number_of_addresses_per_trans = 16;

            if(vif.mon_cb.hburst == INCR4 || vif.mon_cb.hburst== INCR8 || vif.mon_cb.hburst== INCR16)  trans.axi_burst_type=INCR;
            if(vif.mon_cb.hburst == WRAP4 || vif.mon_cb.hburst== WRAP8 || vif.mon_cb.hburst== WRAP16)  trans.axi_burst_type=WRAP;
            if(vif.mon_cb.hburst == SINGLE)  trans.axi_burst_type=FIXED;
            trans.start_addr = vif.mon_cb.haddr;
            
           // number_of_addresses_per_trans--;
            trans.ahb_op_type=vif.mon_cb.hwrite;
            if(vif.mon_cb.hresp == 'b1) trans.ahb_hresp = AHB_ERROR;
            else trans.ahb_hresp = AHB_OKAY;
            //  `uvm_info(get_name(), $sformatf("add %h \n",trans.start_addr), UVM_LOW)
      end
      end//NOSEQ 
        
         if(~vif.mst_cb.hreadyout)@(vif.mst_cb iff vif.mst_cb.hreadyout);

         while(number_of_addresses_per_trans) begin
         //in case of last SEQ collect data, send trans and finish transfer
            @(vif.mst_cb iff ((vif.mst_cb.hreadyout && (vif.mon_cb.htrans !=BUSY) &&vif.mon_cb.hwrite )) || 
                               ( vif.mst_cb.hreadyout &&~vif.mon_cb.hwrite));
          if( number_of_addresses_per_trans == 1 )  begin
           
             if(vif.mon_cb.htrans == NONSEQ &&vif.mst_cb.hreadyout) begin
               trans1 = new;
                //`uvm_info(get_name(), $sformatf("    trans1 = new; \n"), UVM_LOW)
               trans1.ahb_op_type = vif.mon_cb.hwrite;
               trans1.ahb_burst_type = vif.mon_cb.hburst; 
               trans1.ahb_size_type = vif.mon_cb.hsize;
              // trans1.ahb_wstrobe = vif.mon_cb.hwstrobe;
               trans1.start_addr = vif.mon_cb.haddr;
               // if(vif.mon_cb.hresp == 'b1) trans1.ahb_hresp = AHB_ERROR;
               //  else trans1.ahb_hresp = AHB_OKAY;
               pending = 1;
            end
            if(trans.ahb_op_type == AHB_WRITE)
               trans.ahb_data.push_back(vif.mon_cb.hwdata);
           else trans.ahb_data.push_back(vif.mon_cb.hrdata);//`uvm_info(get_name(), $sformatf("number_of_addresses_per_trans %d trans.ahb_data %h",number_of_addresses_per_trans, vif.mon_cb.hrdata), UVM_LOW)
           trans.ahb_wstrobe = vif.mon_cb.hwstrobe;
           trans.ahb_trans_delay = temp_delay;
           trans.ahb_ready_delay = hready_delay;
           trans.busy_cycles     = BUSY_cycles;
           
           transfer_number++;
           item_collected_port.write(trans);          
      //  `uvm_info(get_name(), $sformatf("The AHB MONITOR %d \n%s",transfer_number,trans.sprint()), UVM_LOW)
            ->ahb_trans_cov_e;
            
            
           if(trans.ahb_op_type == AHB_WRITE) 
             this.sample_hwdata(vif.mon_cb.hwdata);
            else 
             this.sample_hrdata(vif.mon_cb.hrdata);
             
            if(pending)begin
              trans = trans1;
              
              if(trans.ahb_burst_type == INCR4 || trans.ahb_burst_type== WRAP4) 
                number_of_addresses_per_trans = 5;
              else 
              if(trans.ahb_burst_type == SINGLE) 
                number_of_addresses_per_trans = 2;
              else  
              if(trans.ahb_burst_type == INCR8 || trans.ahb_burst_type== WRAP8) 
                number_of_addresses_per_trans = 9;
              else  
              if(trans.ahb_burst_type == INCR16 || trans.ahb_burst_type== WRAP16) 
                number_of_addresses_per_trans = 17;
                pending =0;
                
            end
             
          end//last
     
          else begin
            if(vif.mon_cb.hresp == 'b1) trans.ahb_hresp = AHB_ERROR;
            if(trans.ahb_op_type== AHB_WRITE)begin
              trans.ahb_data.push_back(vif.mon_cb.hwdata); 
            end
            else begin
              if(vif.mon_cb.htrans == BUSY)begin
                trans.ahb_data.push_back(vif.mon_cb.hrdata);
              //  `uvm_info(get_name(), $sformatf("number_of_addresses_per_trans %d trans.ahb_data %h",number_of_addresses_per_trans, vif.mon_cb.hrdata), UVM_LOW)
                @(vif.mst_cb iff (vif.mon_cb.htrans !=BUSY));
              end
              else begin
                trans.ahb_data.push_back(vif.mon_cb.hrdata);
               // `uvm_info(get_name(), $sformatf("number_of_addresses_per_trans %d trans.ahb_data %h",number_of_addresses_per_trans, vif.mon_cb.hrdata), UVM_LOW)
              end
            end
          end
         
         number_of_addresses_per_trans--;

        end//while
   endtask: monitor
   /*
   task monitor();
     trans = new;
    // if(vif.mon_cb.htrans != NONSEQ )  @(vif.mst_cb iff vif.mon_cb.htrans == NONSEQ);
    // when is NONSEQ collects all control signals and assign value for number_of_addresses_per_trans which counts the addresses in transfer
     begin 
     if(pending == 0)begin
            trans.ahb_size_type  = vif.mon_cb.hsize   ;
            trans.ahb_burst_type = vif.mon_cb.hburst  ;
            trans.ahb_wstrobe    = vif.mon_cb.hwstrobe;
            
            if(vif.mon_cb.hburst == INCR4 || vif.mon_cb.hburst== WRAP4) 
               number_of_addresses_per_trans = 4;
            else 
            if(vif.mon_cb.hburst == SINGLE) 
               number_of_addresses_per_trans = 1;
            else  
            if(vif.mon_cb.hburst == INCR8 || vif.mon_cb.hburst== WRAP8) 
               number_of_addresses_per_trans = 8;
            else  
            if(vif.mon_cb.hburst == INCR16 || vif.mon_cb.hburst== WRAP16) 
               number_of_addresses_per_trans = 16;
               
            trans.start_addr = vif.mon_cb.haddr;
            
           // number_of_addresses_per_trans--;
            trans.ahb_op_type=vif.mon_cb.hwrite;
            if(vif.mon_cb.hresp == 'b1) trans.ahb_hresp = AHB_ERROR;
            else trans.ahb_hresp = AHB_OKAY;
            //  `uvm_info(get_name(), $sformatf("add %h \n",trans.start_addr), UVM_LOW)
      end
      end//NOSEQ 
        
          if(~vif.mst_cb.hreadyout)@(vif.mst_cb iff vif.mst_cb.hreadyout);

         while(number_of_addresses_per_trans) begin
         //in case of last SEQ collect data, send trans and finish transfer
            @(vif.mst_cb iff (vif.mst_cb.hreadyout && (vif.mon_cb.htrans !=BUSY)));
          if( number_of_addresses_per_trans == 1 )
           begin
           
             if(vif.mon_cb.htrans == NONSEQ ) begin
               trans1 = new;
                //`uvm_info(get_name(), $sformatf("    trans1 = new; \n"), UVM_LOW)
               trans1.ahb_op_type = vif.mon_cb.hwrite;
               trans1.ahb_burst_type = vif.mon_cb.hburst; 
               trans1.ahb_size_type = vif.mon_cb.hsize;
               trans1.ahb_wstrobe = vif.mon_cb.hwstrobe;
               trans1.start_addr = vif.mon_cb.haddr;
                if(vif.mon_cb.hresp == 'b1) trans1.ahb_hresp = AHB_ERROR;
                 else trans1.ahb_hresp = AHB_OKAY;
               pending = 1;
            end
            if(vif.mon_cb.hwrite == AHB_WRITE)
               trans.ahb_data.push_back(vif.mon_cb.hwdata);
            else
            trans.ahb_data.push_back(vif.mon_cb.hrdata);
            
           trans.ahb_trans_delay = temp_delay;
           trans.ahb_ready_delay = hready_delay;
           trans.busy_cycles     = BUSY_cycles;
           
           transfer_number++;
           item_collected_port.write(trans);          
          `uvm_info(get_name(), $sformatf("The AHB MONITOR %d \n%s",transfer_number,trans.sprint()), UVM_LOW)
            ->ahb_trans_cov_e;
            
            
           if(trans.ahb_op_type == AHB_WRITE) 
             this.sample_hwdata(vif.mon_cb.hwdata);
            else 
             this.sample_hrdata(vif.mon_cb.hrdata);
             
            if(pending)begin
               trans = trans1;
            
            if(trans.ahb_burst_type == INCR4 || trans.ahb_burst_type== WRAP4) 
               number_of_addresses_per_trans = 5;
            else 
            if(trans.ahb_burst_type == SINGLE) 
               number_of_addresses_per_trans = 2;
            else  
            if(trans.ahb_burst_type == INCR8 || trans.ahb_burst_type== WRAP8) 
               number_of_addresses_per_trans = 7;
            else  
            if(trans.ahb_burst_type == INCR16 || trans.ahb_burst_type== WRAP16) 
               number_of_addresses_per_trans = 17;
               pending =0;
             end
             
          end//last
     
          else 
          begin
          if(vif.mon_cb.hresp == 'b1) trans.ahb_hresp = AHB_ERROR;
          if(vif.mon_cb.hwrite == AHB_WRITE)begin
            trans.ahb_data.push_back(vif.mon_cb.hwdata); 
          end
          else
            trans.ahb_data.push_back(vif.mon_cb.hrdata);
          end
         
         number_of_addresses_per_trans--;
        

        end//while
   endtask: monitor
   */
 
   // Task used in coverage collection
   task ahb_signal_toggle();
      forever begin
         @( vif.hsel or vif.hwrite or vif.hreadyout or vif.hresp or vif.mon_cb.htrans or vif.hsize or vif.hwstrobe);
         -> ahb_signal_cov_e;
      end
   endtask
   
    task ahb_busy_toggle();
      forever begin
         @( BUSY_after_BUSY or BUSY_after_NONSEQ or BUSY_after_SEQ or BUSY_before_SEQ_and_not_last or BUSY_before_SEQ_and_last);
         -> ahb_busy_cov_e;
      end
   endtask
   
   task ahb_checkers_toggle();
      forever begin
         @(seq_transfer_check_sig or busy_transfer_check_seq_sig  or busy_transfer_check_sig  or 
         idle_transfer_check_sig  or stable_data_check_sig  or
         hburst_transfer_check_4_sig or hburst_transfer_check_8_sig or hburst_transfer_check_16_sig or
         address_calculated_correctly_INCR4 or address_calculated_correctly_INCR8 or address_calculated_correctly_INCR16 or
         address_calculated_correctly_WRAP4 or address_calculated_correctly_WRAP8 or address_calculated_correctly_WRAP16);
         -> ahb_checkers_cov_e;
      end
   endtask

   // Task which monitors HW resets in the middle of the simulation
   task monitor_hw_reset();
      // Go over the initial reset
      @(negedge vif.hreset_n);
      forever begin
         @(negedge vif.hreset_n);
         -> ahb_reset_cov_e;
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
     // `uvm_info(get_name(), $sformatf("AHB Monitor has collected %0d transfers",transfer_number), UVM_LOW)
   endfunction
   

//************************************************************ PROTOCOL CHECKERS ************************************************
// During a waited transfer for a fixed-length burst, the Manager is permitted to change the transfer type from BUSY to SEQ 
// When a Manager uses the BUSY transfer type, the address and control signals must reflect the next transfer in the burst
   task busy_transfer_check();
    bit [31:0] address      ;
    int        trans_size   ;
    int        trans_burst  ;
    int        trans_op_type;
    bit [31:0] wr_data      ;
    bit [31:0] rd_data      ;
    
    forever begin 
      address       = 'h0;
      trans_burst   =   0;
      trans_size    =   0;
      trans_op_type =   0;
      wr_data       = 'h0;
      rd_data       = 'h0;
      
      //Put the values of haddr, hsize, hburst, hwrite, hwdata, hrdata in local variables when htrans is in BUSY state
      if(vif.mon_cb.htrans == BUSY)
      begin
          address       = vif.mon_cb.haddr ;
          trans_size    = vif.mon_cb.hsize ;
          trans_burst   = vif.mon_cb.hburst;
          trans_op_type = vif.mon_cb.hwrite;
          wr_data       = vif.mon_cb.hwdata;
          rd_data       = vif.mon_cb.hrdata;

          wait(vif.mon_cb.htrans != BUSY);
          
          //Check if after BUSY state comes SEQ state when hburst is not SINGLE
          if(vif.mon_cb.htrans != SEQ && vif.mon_cb.hburst != SINGLE)
             uvm_report_error("HTRANS" , "htrans dont changed to SEQ after a BUSY transfer");
             
          
          if(vif.mon_cb.htrans == SEQ && vif.mon_cb.hburst != SINGLE)
          begin  
             
             //If htrans is in SEQ state and hburst is not SINGLE, check if haddr remain stable from BUSY to SEQ
             if(address != vif.mon_cb.haddr)
                uvm_report_error("HADDR" , "haddr has changedafter a BUSY transfer");
             
             //If htrans is in SEQ state and hburst is not SINGLE, check if hsize remain stable from BUSY to SEQ
             if(trans_size != vif.mon_cb.hsize)
                uvm_report_error("HSIZE" , "hsize has changed ");
             
             //If htrans is in SEQ state and hburst is not SINGLE, check if hburst remain stable from BUSY to SEQ
             if(trans_burst != vif.mon_cb.hburst)
                uvm_report_error("HBURST" , "hburst has changed");
             
             //If htrans is in SEQ state and hburst is not SINGLE, check if hwrite remain stable from BUSY to SEQ
             if(trans_op_type != vif.mon_cb.hwrite)
                uvm_report_error("HWRITE" , "hwrite has changed");
             
             //If htrans is in SEQ state and hburst is not SINGLE, check if hwdata remain stable from BUSY to SEQ
             if(wr_data != vif.mon_cb.hwdata)
                uvm_report_error("HWDATA" , "hwdata  has changed");
             
             //If htrans is in SEQ state and hburst is not SINGLE, check if hrdata remain stable from BUSY to SEQ
            // if(rd_data != vif.mon_cb.hrdata)
             //   uvm_report_error("HRDATA" , "hrdata has changed");
             
             //FLAG to check if the checker passed or not
             if(address == vif.mon_cb.haddr      && trans_size == vif.mon_cb.hsize     && 
                trans_burst == vif.mon_cb.hburst && trans_op_type == vif.mon_cb.hwrite && 
                wr_data == vif.mon_cb.hwdata     && rd_data == vif.mon_cb.hrdata) 
               busy_transfer_check_sig = 'b1;
         end
      end
     @(vif.mst_cb); 
    end
   endtask: busy_transfer_check
   
   
//************************************************************************************************************  
// Check if the control information is identical to the previous transfer when is SEQ transfer type 
   task seq_transfer_check();
    int trans_size   ;
    int trans_burst  ;
    int trans_op_type;
    
    forever begin 
      trans_size    = 0;
      trans_burst   = 0;
      trans_op_type = 0;
      
      //Put the values of hsize, hburst, hwrite in local variables when hreadyout is HIGH, htrans is in NONSEQ state and hreasp is LOW
      if(vif.mon_cb.htrans == NONSEQ && vif.mon_cb.hreadyout == 1'b1 && vif.mon_cb.hresp == 1'b0)
      begin
          trans_size    = vif.mon_cb.hsize ;
          trans_burst   = vif.mon_cb.hburst;
          trans_op_type = vif.mon_cb.hwrite;
          
          @(vif.mst_cb);
          
          //check if htrans is in SEQ state next clock
          if(vif.mon_cb.htrans == SEQ)
          begin
             // Check if value of hsize, hburst or hwrite has changed
             if((trans_size != vif.mon_cb.hsize) || (trans_burst != vif.mon_cb.hburst) || (trans_op_type != vif.mon_cb.hwrite))
                uvm_report_error("CONTROL SIGNALS" , "hsize has changed or hburst has changed or hwrite has changed");
             
             //FLAG to check if the checker passed or not
             if(trans_size == vif.mon_cb.hsize && trans_burst == vif.mon_cb.hburst && trans_op_type == vif.mon_cb.hwrite) 
               seq_transfer_check_sig = 'b1;
          end
      end
      @(vif.mst_cb);
    end
   endtask: seq_transfer_check
   
//************************************************************************************************************  
//Check if during a waited transfer, the Manager is permitted to change the transfer type from IDLE to NONSEQ
   task idle_transfer_check();
    forever begin
      if((vif.mon_cb.htrans == IDLE) && (vif.mon_cb.hreadyout == 'b0))
      begin
         wait(vif.mon_cb.htrans != IDLE);
         
         if(vif.mon_cb.htrans != NONSEQ)
            uvm_report_error("HTRANS" , "htrans don´t change to NONSEQ after a IDLE transfer");
            
        //FLAG to check if the checker passed or not
        idle_transfer_check_sig = ~idle_transfer_check_sig;
      end
      @(vif.mst_cb);
    end
   endtask: idle_transfer_check
  
  
//************************************************************************************************************     
//Check when hready is LOW then haddr and hrdata and hwdata should remain in the same state until it hready goes HIGH
   task stable_data_check();
      bit [31:0] address;
      bit [31:0] wr_data;
      bit [31:0] rd_data;
    forever begin
      address = 'h0;
      wr_data = 'h0;
      rd_data = 'h0;
      
      //Put the values of haddr, hrdata, hwdata in local variables when hreadyout is LOW and htrans is in NONSEQ state or SEQ state
      if(vif.mon_cb.hreadyout == 0 && (vif.mon_cb.htrans == NONSEQ || vif.mon_cb.htrans == SEQ ))
      begin
         address = vif.mon_cb.haddr;
         wr_data = vif.mon_cb.hwdata;
         rd_data = vif.mon_cb.hrdata;
         
         @(vif.mst_cb);
         
         //Check if value of haddr has changed the next clock if hreadyout is still LOW 
         if(vif.mon_cb.hreadyout == 0 && (address != vif.mon_cb.haddr))
            uvm_report_error("HADDR" , "haddr don´t remain stable!");
         
         //Check if value of hwdata has changed the next clock if hreadyout is still LOW 
         if(vif.mon_cb.hreadyout == 0 && (wr_data != vif.mon_cb.hwdata))
            uvm_report_error("HWDATA" , "hwdata don´t remain stable!");
         
          //Check if value of hrdata has changed the next clock if hreadyout is still LOW 
        // if(vif.mon_cb.hreadyout == 0 && (rd_data != vif.mon_cb.hrdata))
           // uvm_report_error("HRDATA" , "hrdata don´t remain stable!");
         
         //FLAG to check if the checker passed or not
         if(vif.mon_cb.hreadyout == 0  && address == vif.mon_cb.haddr && wr_data == vif.mon_cb.hwdata && rd_data == vif.mon_cb.hrdata)
           stable_data_check_sig = 'b1;
      end
      @(vif.mst_cb);
    end
   endtask : stable_data_check
   
  
//************************************************************************************************************    
// Check if hburst generates transfer correctly (check if it generates the number of addresses correctly) 
// and if address is computed correctly (INCR and WRAP cases)
  task hburst_transfer_check();
    int        num_of_addr_incr             ;
    int        number_of_addresses_per_trans;
    int        num_of_addr_dec              ;
    bit [31:0] address_calculated_correctly ;

    num_of_addr_incr              = 0 ;
    number_of_addresses_per_trans = 0 ;
    num_of_addr_dec               = 0 ; 
    address_calculated_correctly  ='h0;

    forever begin
      //SINGLE CASE
      if(vif.mon_cb.hburst == SINGLE && vif.mon_cb.hsel == 1'b1)
       begin
          number_of_addresses_per_trans= 1;
          num_of_addr_dec = 1;
          num_of_addr_incr++;
          num_of_addr_dec--;
          
          //Check if hburst generates transfer correctly (checking the value of address)
          if((num_of_addr_dec == 0) && (num_of_addr_incr != number_of_addresses_per_trans))
          begin
              uvm_report_error("HBURST" , "hburst don´t generates transfer correctly for SINGLE");
          end

          num_of_addr_incr =  0;
       end

      else
      //INCR4 AND WRAP4 CASES
      if((vif.mon_cb.hburst == INCR4 || vif.mon_cb.hburst == WRAP4) && ((vif.mon_cb.htrans == NONSEQ && vif.mon_cb.hreadyout == 1'b1) || (vif.mon_cb.htrans == SEQ && vif.mon_cb.hreadyout == 1'b1)))
      begin
         number_of_addresses_per_trans = 4;

         if(num_of_addr_dec == 0)
         begin
            num_of_addr_dec = 4;
            address_calculated_correctly = vif.mon_cb.haddr;
         end
         
         //Check if address is computed correctly for INCR4 case
         if((address_calculated_correctly != vif.mon_cb.haddr) && vif.mon_cb.hburst == INCR4)
            uvm_report_error("HADDR" , "haddr is not calculated correctly for INCR4");
         
         //FLAG to check if the checker passed or not when verify if address is computed correctly for INCR4 case
         if((address_calculated_correctly == vif.mon_cb.haddr) && vif.mon_cb.hburst == INCR4)
           address_calculated_correctly_INCR4 = 1'b1;
         
         //Calculate the value of address when hsize is BYTE
         if(vif.mon_cb.hsize == 'b000 && vif.mon_cb.hburst == INCR4)
            address_calculated_correctly = address_calculated_correctly + 3'b001; 
         
         //Calculate the value of address when hsize is HALFWORD
         if(vif.mon_cb.hsize == 'b001 && vif.mon_cb.hburst == INCR4)
            address_calculated_correctly = address_calculated_correctly + 3'b010;
         
         //Calculate the value of address when hsize is WORD
         if(vif.mon_cb.hsize == 'b010 && vif.mon_cb.hburst == INCR4)
            address_calculated_correctly = address_calculated_correctly + 3'b100;
      
         //Check if address is computed correctly for WRAP4 case
         if((address_calculated_correctly != vif.mon_cb.haddr) && vif.mon_cb.hburst == WRAP4)
         begin
            uvm_report_error("HADDR" , "haddr is not calculated correctly for WRAP4");
         end
         
         
        //FLAG to check if the checker passed or not when verify if address is computed correctly for WRAP4 case
         if((address_calculated_correctly == vif.mon_cb.haddr) && vif.mon_cb.hburst == WRAP4)
            address_calculated_correctly_WRAP4 = 1'b1;
         
         //Calculate the value of address when hsize is BYTE
         if(vif.mon_cb.hsize == 'b000 && vif.mon_cb.hburst == WRAP4)
         begin
            address_calculated_correctly[1:0]  = address_calculated_correctly[1:0]  + 1; 
            address_calculated_correctly[31:2] = address_calculated_correctly[31:2]; 
         end
         
         //Calculate the value of address when hsize is HALFWORD
         if(vif.mon_cb.hsize == 'b001 && vif.mon_cb.hburst == WRAP4)
         begin
            address_calculated_correctly[2:1]  = address_calculated_correctly[2:1]  + 1; 
            address_calculated_correctly[31:3] = address_calculated_correctly[31:3]; 
         end
         
         //Calculate the value of address when hsize is WORD
         if(vif.mon_cb.hsize == 'b010 && vif.mon_cb.hburst == WRAP4)
         begin
            address_calculated_correctly[3:2]  = address_calculated_correctly[3:2]  + 1; 
            address_calculated_correctly[31:4] = address_calculated_correctly[31:4]; 
         end

         num_of_addr_incr++;
         num_of_addr_dec--;

         //Check if the hburst generates transfer correctly (checking the value of addresses)
         if(num_of_addr_dec == 0)
         begin
            if(num_of_addr_incr != number_of_addresses_per_trans)
            begin
                uvm_report_error("HBURST" , "hburst don´t generates transfer correctly for INCR4 or WRAP4");
            end
            
            //FLAG to check if the checker passed or not when verify if hburst generates transfer correctly
            if(num_of_addr_incr == number_of_addresses_per_trans)
               hburst_transfer_check_4_sig = 'b1;

            num_of_addr_incr =  0;
         end
      end

      else
      //INCR8 AND WRAP8 CASES
      if((vif.mon_cb.hburst == INCR8 || vif.mon_cb.hburst == WRAP8) && ((vif.mon_cb.htrans == NONSEQ && vif.mon_cb.hreadyout == 1'b1) || (vif.mon_cb.htrans == SEQ && vif.mon_cb.hreadyout == 1'b1)))
      begin
         number_of_addresses_per_trans = 8;

         if(num_of_addr_dec == 0)
         begin
            num_of_addr_dec = 8;
            address_calculated_correctly = vif.mon_cb.haddr;
         end
         
         //Check if address is computed correctly for INCR8 case
         if((address_calculated_correctly != vif.mon_cb.haddr) && vif.mon_cb.hburst == INCR8)
            uvm_report_error("HADDR" , "haddr is not calculated correctly for INCR8");
         
         //FLAG to check if the checker passed or not when verify if address is computed correctly for INCR8 case
         if((address_calculated_correctly == vif.mon_cb.haddr) && vif.mon_cb.hburst == INCR8)
            address_calculated_correctly_INCR8 = 1'b1;
         
         //Calculate the value of address when hsize is BYTE
         if(vif.mon_cb.hsize == 'b000 && vif.mon_cb.hburst == INCR8)
            address_calculated_correctly = address_calculated_correctly + 3'b001; 
         
         //Calculate the value of address when hsize is HALFWORD
         if(vif.mon_cb.hsize == 'b001 && vif.mon_cb.hburst == INCR8)
            address_calculated_correctly = address_calculated_correctly + 3'b010;
         
         //Calculate the value of address when hsize is WORD
         if(vif.mon_cb.hsize == 'b010 && vif.mon_cb.hburst == INCR8)
            address_calculated_correctly = address_calculated_correctly + 3'b100;
         
         //Check if address is computed correctly for WRAP8 case
         if((address_calculated_correctly != vif.mon_cb.haddr) && vif.mon_cb.hburst == WRAP8)
         begin
            uvm_report_error("HADDR" , "haddr is not calculated correctly for WRAP8");
         end
         
         //FLAG to check if the checker passed or not when verify if address is computed correctly for WRAP8 case
         if((address_calculated_correctly == vif.mon_cb.haddr) && vif.mon_cb.hburst == WRAP8)
            address_calculated_correctly_WRAP8 = 1'b1;
         
         //Calculate the value of address when hsize is BYTE
         if(vif.mon_cb.hsize == 'b000 && vif.mon_cb.hburst == WRAP8)
         begin
            address_calculated_correctly[2:0]  = address_calculated_correctly[2:0]  + 1; 
            address_calculated_correctly[31:3] = address_calculated_correctly[31:3]; 
         end
         
         //Calculate the value of address when hsize is HALFWORD
         if(vif.mon_cb.hsize == 'b001 && vif.mon_cb.hburst == WRAP8)
         begin
            address_calculated_correctly[3:1]  = address_calculated_correctly[3:1]  + 1; 
            address_calculated_correctly[31:4] = address_calculated_correctly[31:4]; 
         end
         
         //Calculate the value of address when hsize is WORD
         if(vif.mon_cb.hsize == 'b010 && vif.mon_cb.hburst == WRAP8)
         begin
            address_calculated_correctly[4:2]  = address_calculated_correctly[4:2]  + 1; 
            address_calculated_correctly[31:5] = address_calculated_correctly[31:5]; 
         end

         num_of_addr_incr++;
         num_of_addr_dec--;
         
         //Check if the hburst generates transfer correctly (checking the value of addresses)
         if(num_of_addr_dec == 0)
         begin
            if(num_of_addr_incr != number_of_addresses_per_trans)
            begin
                uvm_report_error("HBURST" , "hburst don´t generates transfer correctly for INCR8 or WRAP8");
            end
            
            //FLAG to check if the checker passed or not when verify if hburst generates transfer correctly
            if(num_of_addr_incr == number_of_addresses_per_trans)
               hburst_transfer_check_8_sig = 'b1;

            num_of_addr_incr =  0;
         end
      end

      else
      //INCR16 AND WRAP16 CASES
      if((vif.mon_cb.hburst == INCR16 || vif.mon_cb.hburst == WRAP16) && ((vif.mon_cb.htrans == NONSEQ && vif.mon_cb.hreadyout == 1'b1) || (vif.mon_cb.htrans == SEQ && vif.mon_cb.hreadyout == 1'b1)))
      begin
         number_of_addresses_per_trans = 16;

         if(num_of_addr_dec == 0)
         begin
            num_of_addr_dec = 16;
            address_calculated_correctly = vif.mon_cb.haddr;
         end
         
         //Check if address is computed correctly for INCR16 case
         if((address_calculated_correctly != vif.mon_cb.haddr) && vif.mon_cb.hburst == INCR16)
            uvm_report_error("HADDR" , "haddr is not calculated correctly for INCR16");
         
         //FLAG to check if the checker passed or not when verify if address is computed correctly for INCR16 case
         if((address_calculated_correctly == vif.mon_cb.haddr) && vif.mon_cb.hburst == INCR16)
            address_calculated_correctly_INCR16 = 1'b1;
         
         //Calculate the value of address when hsize is BYTE
         if(vif.mon_cb.hsize == 'b000 && vif.mon_cb.hburst == INCR16)
            address_calculated_correctly = address_calculated_correctly + 3'b001; 
         
         //Calculate the value of address when hsize is HALFWORD
         if(vif.mon_cb.hsize == 'b001 && vif.mon_cb.hburst == INCR16)
            address_calculated_correctly = address_calculated_correctly + 3'b010;
         
         //Calculate the value of address when hsize is WORD
         if(vif.mon_cb.hsize == 'b010 && vif.mon_cb.hburst == INCR16)
            address_calculated_correctly = address_calculated_correctly + 3'b100;
            
         //Check if address is computed correctly for WRAP16 case  
         if((address_calculated_correctly != vif.mon_cb.haddr) && vif.mon_cb.hburst == WRAP16)
         begin
            uvm_report_error("HADDR" , "haddr is not calculated correctly for WRAP16");
         end
         
         //FLAG to check if the checker passed or not when verify if address is computed correctly for WRAP16 case
         if((address_calculated_correctly == vif.mon_cb.haddr) && vif.mon_cb.hburst == WRAP16)
            address_calculated_correctly_WRAP16 = 1'b1;
         
         //Calculate the value of address when hsize is BYTE
         if(vif.mon_cb.hsize == 'b000 && vif.mon_cb.hburst == WRAP16)
         begin
            address_calculated_correctly[3:0]  = address_calculated_correctly[3:0]  + 1; 
            address_calculated_correctly[31:4] = address_calculated_correctly[31:4]; 
         end
         
         //Calculate the value of address when hsize is HALFWORD
         if(vif.mon_cb.hsize == 'b001 && vif.mon_cb.hburst == WRAP16)
         begin
            address_calculated_correctly[4:1]  = address_calculated_correctly[4:1]  + 1; 
            address_calculated_correctly[31:5] = address_calculated_correctly[31:5]; 
         end
         
         //Calculate the value of address when hsize is WORD
         if(vif.mon_cb.hsize == 'b010 && vif.mon_cb.hburst == WRAP16)
         begin
            address_calculated_correctly[5:2]  = address_calculated_correctly[5:2]  + 1; 
            address_calculated_correctly[31:6] = address_calculated_correctly[31:6]; 
         end

         num_of_addr_incr++;
         num_of_addr_dec--;
         
         //Check if the hburst generates transfer correctly (checking the value of addresses)
         if(num_of_addr_dec == 0)
         begin
            if(num_of_addr_incr != number_of_addresses_per_trans)
            begin
                uvm_report_error("HBURST" , "hburst don´t generates transfer correctly for INCR16 or WRAP16");
            end
            
            //FLAG to check if the checker passed or not when verify if hburst generates transfer correctly
            if(num_of_addr_incr == number_of_addresses_per_trans)
               hburst_transfer_check_16_sig = 'b1;

            num_of_addr_incr =  0;
         end
      end
      @(vif.mst_cb);
    end
   endtask: hburst_transfer_check

endclass:ahb_monitor

`endif