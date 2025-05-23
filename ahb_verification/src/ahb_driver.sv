//------------------------------------
// File name   : ahb_driver.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_DRIVER_SV
`define AHB_DRIVER_SV


class ahb_driver #(AW=32,DW=32) extends uvm_driver #(ahb_trans #(AW,DW));
   //MASTER or SLAVE
   ahb_agent_kind_t agent_kind;
  
   bit [31:0] pending_data; // used to save last data from a transfer when trans_delay==0 (back to back transaction)
   bit trans_pending = 0;   // used to check if we have a data in pending, if is a back to back transaction
  
   bit reactive_slave;      // config for slave: 1 - REACTIVE SLAVE; 0 - ACTIVE SLAVE
   int probability_of_ERROR;// config to set probability of error in reactive slave (1:= probability_of_ERROR; 0:= 100)
   bit busy_enable;
   bit idle_enable;
   bit hresp_error_enable;
   bit one_kb_boundry_enable;
   rand bit err;            // 0 - OKAY, 1 - ERROR
   
   bit [AW-1:0]      ahb_addr  [$]  ;
   bit               busy_bits [$]  ;

   //register with the factory 
   `uvm_component_utils_begin(ahb_driver#(AW,DW))
     `uvm_field_enum(ahb_agent_kind_t, agent_kind, UVM_ALL_ON)
     `uvm_field_int(reactive_slave, UVM_ALL_ON)
     `uvm_field_int(probability_of_ERROR, UVM_ALL_ON)
     `uvm_field_int(busy_enable, UVM_ALL_ON)
     `uvm_field_int(idle_enable, UVM_ALL_ON)
     `uvm_field_int(hresp_error_enable, UVM_ALL_ON)
     `uvm_field_int(one_kb_boundry_enable, UVM_ALL_ON)
   `uvm_component_utils_end

   //ahb interface
   virtual interface ahb_if #(AW,DW) vif;

   function new(string name,uvm_component parent = null);
     super.new(name,parent);
   endfunction:new

   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     //get virtual interface
     if(!uvm_config_db#(virtual ahb_if #(AW,DW))::get(this,"","ahb_vif", vif)) begin
        `uvm_fatal(get_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})
     end
   endfunction:build_phase

   task run_phase(uvm_phase phase);
     super.run_phase(phase);
     drive_reset_values();  //drive reset values
     // Go over initial reset
     @(negedge vif.hreset_n);
     forever
     begin
        while($isunknown(vif.hreset_n) || vif.hreset_n === 1'b0) //reset is x, z or 0
        begin
           drive_reset_values(); //drive reset values
           @(vif.mst_cb);
        end
        seq_item_port.get_next_item(req); //get item from sequencer
        drive_ahb_trans(req);
        seq_item_port.item_done(); //signal the sequencer it's ok to send the next item
     end
   endtask:run_phase

   //idle values for driven signals
   task drive_reset_values();
     case (agent_kind)
       AHB_MASTER: begin
           vif.mst_cb.haddr    <=  'b0;
           vif.mst_cb.hwdata   <=  'b0;
           vif.mst_cb.hsel     <=  'b0;
           vif.mst_cb.hwrite   <=  'b0;
           vif.mst_cb.htrans   <=  'b0;
           vif.mst_cb.hburst   <=  'b0;
           vif.mst_cb.hsize    <=  'b0;
           vif.mst_cb.hwstrobe <=  'b0;
       end
       AHB_SLAVE: begin
          vif.slv_cb.hreadyout <=  'b0;
          vif.slv_cb.hresp     <=  'b0;
          vif.slv_cb.hrdata    <=  'h0;
       end
     endcase
   endtask:drive_reset_values

    function void add_busy_cycles(ahb_trans trans);

    for(int i=0;i<trans.busy_cycles;i++)
      busy_bits.push_back(1);
      
    for(int i=0;i<ahb_addr.size-2;i++)
      busy_bits.push_back(0);
      
    busy_bits.shuffle();
    busy_bits.push_back(0);
    busy_bits.push_front(0);
    
  endfunction : add_busy_cycles
  

  function compute_addr(ahb_trans trans);
  
        if(one_kb_boundry_enable)
          begin
            if(trans.ahb_burst_type == INCR4 || trans.ahb_burst_type == WRAP4)
              trans.start_addr = 1024-(4*(2**trans.ahb_size_type));
            if(trans.ahb_burst_type == INCR8 || trans.ahb_burst_type == WRAP8)
              trans.start_addr = 1024-(8*(2**trans.ahb_size_type));
            if(trans.ahb_burst_type == INCR16 || trans.ahb_burst_type == WRAP16)
              trans.start_addr = 1024-(16*(2**trans.ahb_size_type));
            if(trans.ahb_burst_type == SINGLE)
              trans.start_addr = 1024-(2**trans.ahb_size_type);
          end   
  
       if(trans.ahb_burst_type == INCR4 || trans.ahb_burst_type == WRAP4) 
         for(int i=0;i<4;i++ )
           ahb_addr.push_back(0);
       else
       if(trans.ahb_burst_type == INCR8 || trans.ahb_burst_type == WRAP8) 
          for(int i=0;i<8;i++ )
            ahb_addr.push_back(0);
       else
       if(trans.ahb_burst_type == INCR16 || trans.ahb_burst_type == WRAP16)
         for(int i=0;i<16;i++ )
           ahb_addr.push_back(0);
       else
       if(trans.ahb_burst_type == SINGLE)  
         ahb_addr.push_back(0);
                       
           
     ahb_addr[0] = trans.start_addr;
                             
                   
       if( trans.ahb_burst_type == INCR4 ||  trans.ahb_burst_type == INCR8 ||  trans.ahb_burst_type == INCR16)
         foreach(ahb_addr[i])
           if(i > 0)
             ahb_addr[i] = ahb_addr[i-1] + 2** trans.ahb_size_type;
       if(( trans.ahb_burst_type == WRAP4) && ( trans.ahb_size_type == BYTE))
         foreach (ahb_addr[i])
           if(i != 0)
             ahb_addr[i] = ((((ahb_addr[i-1][1:0]+1) & 32'h0000_0003)) + (ahb_addr[i-1] & 32'hFFFF_FFFC));
             
       if((trans.ahb_burst_type == WRAP4) && (trans.ahb_size_type == HWORD))
         foreach (ahb_addr[i])
           if(i != 0)
             ahb_addr[i] = ((((ahb_addr[i-1][2:1]+1) & 32'h0000_0003)<<1) + (ahb_addr[i-1] & 32'hFFFF_FFF9));
             
       if((trans.ahb_burst_type == WRAP4) && (trans.ahb_size_type == WORD))
         foreach (ahb_addr[i])
            if(i != 0)
              ahb_addr[i] = ((((ahb_addr[i-1][3:2]+1) & 32'h0000_0003)<<2) + (ahb_addr[i-1] & 32'hFFFF_FFF3));
              
       if((trans.ahb_burst_type == WRAP8) && (trans.ahb_size_type == BYTE))
         foreach (ahb_addr[i])
           if(i != 0)
             ahb_addr[i] = ((((ahb_addr[i-1][2:0]+1) & 32'h0000_0007)) + (ahb_addr[i-1] & 32'hFFFF_FFF8));
             
       if((trans.ahb_burst_type == WRAP8) && (trans.ahb_size_type == HWORD))
        foreach (ahb_addr[i])
          if(i != 0)
            ahb_addr[i] = ((((ahb_addr[i-1][3:1]+1) & 32'h0000_0007)<<1) + (ahb_addr[i-1] & 32'hFFFF_FFF1));
            
       if((trans.ahb_burst_type == WRAP8) && (trans.ahb_size_type == WORD))
         foreach (ahb_addr[i])
           if(i != 0)
             ahb_addr[i] = ((((ahb_addr[i-1][4:2]+1) & 32'h0000_0007)<<2) + (ahb_addr[i-1] & 32'hFFFF_FFE3));
             
       if((trans.ahb_burst_type == WRAP16) && (trans.ahb_size_type == BYTE))
         foreach (ahb_addr[i])
           if(i != 0)
            ahb_addr[i] = ((((ahb_addr[i-1][3:0]+1) & 32'h0000_000F)) + (ahb_addr[i-1] & 32'hFFFF_FFF0));
            
       if((trans.ahb_burst_type == WRAP16) && (trans.ahb_size_type == HWORD))
         foreach (ahb_addr[i])
          if(i != 0)
           ahb_addr[i] = ((((ahb_addr[i-1][4:1]+1) & 32'h0000_000F)<<1) + (ahb_addr[i-1] & 32'hFFFF_FFE1));
           
       if((trans.ahb_burst_type == WRAP16) && (trans.ahb_size_type == WORD))
         foreach (ahb_addr[i])
           if(i != 0)
             ahb_addr[i] = ((((ahb_addr[i-1][5:2]+1) & 32'h0000_000F)<<2) + (ahb_addr[i-1] & 32'hFFFF_FFC3));
       
       
       if(trans.ahb_size_type == HWORD)
         foreach(ahb_addr[i])
           ahb_addr[i][0] = 0;
       if(trans.ahb_size_type == WORD)
         foreach(ahb_addr[i])
           ahb_addr[i][1:0] = 0;   
     
           
  endfunction
   
   //drive AHB transaction
task drive_ahb_trans(ahb_trans #(AW,DW) trans);
      case (agent_kind)
         AHB_MASTER:
         begin
            int i,j,k,num_of_addr;
            i           = 0;
            j           = 0; //for address incrementation
            k           = 0; //for hwdata incrementation
            num_of_addr = 0; //for address decrementation; when 0 the address phase is ready; data phase has one more data to transmit
           
           `uvm_info(get_name(), $sformatf("The AHB MASTER Driver will start the following transfer:\n%s",trans.sprint()), UVM_LOW)
           
           
            vif.mst_cb.hsel   <= 1'b1;
               
            if(idle_enable && trans.idle_cycles_start) //used to insert IDLE in front of NONSEQ
            begin
               vif.mst_cb.htrans <= IDLE;
               repeat(trans.idle_cycles_start) @(vif.mst_cb);
            end
           
           
            void'(compute_addr(trans));
           
            num_of_addr = ahb_addr.size;
           
            if(busy_enable && trans.ahb_burst_type != SINGLE) void'(add_busy_cycles(trans)); //if we want a transfer with BUSY we have to update the HTRANS queue with busy inserted
            else begin
            for(int i=0;i<num_of_addr;i++)
              busy_bits.push_back(0);
            end
            if(i==0)begin
                  vif.mst_cb.hwrite   <= trans.ahb_op_type;
                  vif.mst_cb.hsize    <= trans.ahb_size_type ;
                  vif.mst_cb.hburst   <= trans.ahb_burst_type;
                  vif.mst_cb.htrans   <= NONSEQ;
                  vif.mst_cb.haddr    <= ahb_addr[j];
                  vif.mst_cb.hwstrobe <= trans.ahb_wstrobe;
                  j++;
                  num_of_addr--;
                  //if we have a data in pending(we had a transaction before with 0 delay - back2back) we have to put in on NONSEQ
                  if(vif.mst_cb.hwrite == AHB_WRITE)
                  begin
                     if(trans_pending == 1)
                     begin
                        vif.mst_cb.hwdata <= pending_data; // put data on wave
                        trans_pending = 0;                 // we don't have a data in pending      
                     end  
                  end
                  @(vif.mst_cb iff vif.mst_cb.hreadyout);
                  i++;
             end
             //foreach(busy_bits[i])begin
             while(i<busy_bits.size)
              begin
                 if(busy_bits[i]==0)begin
                  if(j<ahb_addr.size && trans.ahb_burst_type != SINGLE)
                  begin
                     vif.mst_cb.htrans   <= SEQ;
                     vif.mst_cb.haddr <= ahb_addr[j];
                     j++;
                     
                     if(num_of_addr)
                        num_of_addr--;
                  end
                  if(vif.mst_cb.hwrite == AHB_WRITE)
                  begin
                     if(k<trans.ahb_data.size-1 )
                     begin
                        vif.mst_cb.hwdata <= trans.ahb_data[k];
                        k++;
                     end
                  end
                 end//seq
                 else begin
                   if(trans.ahb_burst_type != SINGLE)
                   begin
                     vif.mst_cb.haddr <= ahb_addr[j];
                     vif.mst_cb.htrans   <= BUSY;
                     
                   if(vif.mst_cb.hwrite == AHB_WRITE)
                      if(k<trans.ahb_data.size)
                        vif.mst_cb.hwdata <= trans.ahb_data[k];
                   end
                 end//busy
                 if(busy_bits[i] == 0)
                      @(vif.mst_cb iff vif.mst_cb.hreadyout);
                 else
                      @(vif.mst_cb);
                 i++;
               end//i!=0
           
       
            vif.mst_cb.htrans <= IDLE;
            // wait for transfer to be done
            if( num_of_addr == 0 && vif.mst_cb.hwrite == AHB_WRITE && trans.ahb_trans_delay ==0)  
            begin
              //in case of back to back put data in pending
               pending_data = trans.ahb_data[k];
               trans_pending = 1;
            end
           
            //drive last data and finish transfer in case is not a back2back transaction
            if(trans.ahb_trans_delay !=0)
            begin
               if(vif.mst_cb.hwrite == AHB_WRITE)
               begin
                  if(k<trans.ahb_data.size)
                     vif.mst_cb.hwdata <= trans.ahb_data[k]; //data phase finished
               end
            end

            //last cycle of hsel (it has to be over last data)
            wait(num_of_addr == 0 && vif.mst_cb.hreadyout == 1'b1 && vif.mst_cb.hsel <= 1'b1) ;
 
            if(trans.ahb_trans_delay!=0)
               @(vif.mst_cb iff vif.mst_cb.hreadyout == 1'b1);
               
            vif.mst_cb.hsel <= 1'b0;    
            busy_bits.delete();
            ahb_addr.delete();
            if(trans.ahb_trans_delay!=0 && trans.idle_cycles_end && idle_enable) // IDLE cycles after last data
            begin
               vif.mst_cb.htrans <= IDLE;
               repeat(trans.idle_cycles_end) @(vif.mst_cb);
            end
           
            // Inter-transaction delay
            repeat (trans.ahb_trans_delay) @(vif.mst_cb);
            `uvm_info(get_name(), $sformatf("The AHB MASTER Driver has finished driving a transfer!"), UVM_LOW)
         end //case MASTER
         
         
      AHB_SLAVE:
         //reactive slave random hreadyout, random error with probability set in config, random hrdata
            if(reactive_slave == 1)
            begin
               @(vif.slv_cb);
               forever // random hresp and random hreadyout
               begin
                 while (~(vif.slv_cb.hsel )) //when slave is not selected, it has to wait
                   @(vif.slv_cb);
                   
               if(hresp_error_enable)  
                  randomize(err) with {err dist {1:= probability_of_ERROR, 0:=100};}; //randomize error with probability set in config
               else err = 0;
                 
                if(err == 1)
                 begin // ERROR
                   vif.slv_cb.hresp <= 1;
                   vif.slv_cb.hreadyout <= 'b0;
                   @(vif.slv_cb);
                   vif.slv_cb.hreadyout <= 'b1;
                   @(vif.slv_cb);
                   vif.slv_cb.hresp     <= 'b0;
                   @(vif.slv_cb);
                 end
                 else begin // NO ERROR
                   vif.slv_cb.hresp <= 0;
                   vif.slv_cb.hreadyout <= $random;
                 end
                // drive random data
                if((vif.slv_cb.hreadyout && vif.slv_cb.htrans==SEQ && vif.slv_cb.hwrite == AHB_READ)||(vif.slv_cb.hreadyout && vif.slv_cb.htrans==NONSEQ && vif.slv_cb.hwrite == AHB_READ))
                 begin
                    vif.slv_cb.hrdata <= $random;
                 end
                 @(vif.slv_cb);
                end
            end // reactive slave
     
            else // ACTIVE SLAVE                      
            begin  // Drive DATA, ERROR & HREADYOT
               int data_index; // For hrdata incrementation
               int err_pos   ; // For randomize the position of error in a transfer
               
               data_index=0;
               
               // Drive HREADYOUT
               while(vif.slv_cb.hreadyout == 'b0)
               begin
                  if(trans.ahb_hready_kind == ALWAYS_1)
                     vif.slv_cb.hreadyout <= 1'b1;
                     
                  else
                  if(trans.ahb_hready_kind == TOGGLE_1 && (!(hresp_error_enable && (vif.slv_cb.hburst == SINGLE))))
                    vif.slv_cb.hreadyout <= ~vif.slv_cb.hreadyout;
                 
                  else
                  if(trans.ahb_hready_kind == RANDOM && (!(hresp_error_enable && (vif.slv_cb.hburst == SINGLE))))
                   vif.slv_cb.hreadyout <= $random;
                 
                  @(vif.slv_cb);
               end
               
               if(vif.slv_cb.htrans == IDLE)
                 @(vif.slv_cb iff (/*vif.slv_cb.hreadyout &&*/ vif.slv_cb.htrans != IDLE));
               `uvm_info(get_name(), $sformatf("The AHB SLAVE Driver will start the following transfer:\n%s",trans.sprint()), UVM_LOW)
               
               // Randomize the position of error in a transfer
               if(hresp_error_enable && trans.error_enable )
                  err_pos = $urandom_range(0, trans.ahb_data.size-1);
                 
               // SINGLE CASE & ERROR
               if(vif.slv_cb.hburst == SINGLE && hresp_error_enable && trans.error_enable)
               begin              
                  //Drive data in 0 when is ERROR
                  vif.slv_cb.hrdata    <= 'h0;
                     
                  //Drive ERROR
                  vif.slv_cb.hresp     <= 'b1;
                  vif.slv_cb.hreadyout <= 'b0;
                  @(vif.slv_cb);
                  vif.slv_cb.hreadyout <= 'b1;
                     
                  // Drive data when is NO ERROR and back to back transaction
                  if(vif.slv_cb.htrans == NONSEQ  && vif.slv_cb.hwrite == AHB_READ && vif.slv_cb.hreadyout && !trans.error_enable)
                  begin
                     vif.slv_cb.hresp     <= 'b0;
                     vif.slv_cb.hrdata <= trans.ahb_data[data_index];                  
                  end//SINGLE & NO ERROR & B2B
               end //SINGLE & ERROR
               else  
               
               // SINGLE CASE & NO  ERROR
               // INCR3, WRAP4, INCR8, WRAP8, INCR16, WRAP16 CASES WITH ERROR & NO ERROR
               while(data_index < trans.ahb_data.size)
               begin                  
                  //INCR3, WRAP4, INCR8, WRAP8, INCR16, WRAP16 CASES & ERROR
                  if((data_index == err_pos) && vif.slv_cb.hreadyout && hresp_error_enable && trans.error_enable && (vif.slv_cb.htrans != BUSY))
                  begin
                     //If it´s error, put hrdata in 0
                     vif.slv_cb.hrdata    <= 'h0;
                     data_index++;
                     
                     //Drive error
                     vif.slv_cb.hresp     <= 'b1;
                     vif.slv_cb.hreadyout <= 'b0;
                     @(vif.slv_cb);
                     vif.slv_cb.hreadyout <= 'b1;                    
                  end //INCR3, WRAP4, INCR8, WRAP8, INCR16, WRAP16 CASES & ERROR
                 
                  //SINGLE, INCR3, WRAP4, INCR8, WRAP8, INCR16, WRAP16 CASES & NO ERROR
                  else                                      
                  begin
                     vif.i = data_index;
                     vif.slv_cb.hresp <= 'b0;
                         
                     // Drive HREADYOUT
                     if(trans.ahb_hready_kind == ALWAYS_1)
                     vif.slv_cb.hreadyout <= 1'b1;
                     
                     else
                     if(trans.ahb_hready_kind == TOGGLE_1 && (!(hresp_error_enable && (vif.slv_cb.hburst == SINGLE))))
                        vif.slv_cb.hreadyout <= ~vif.slv_cb.hreadyout;
                 
                     else
                     if(trans.ahb_hready_kind == RANDOM && (!(hresp_error_enable && (vif.slv_cb.hburst == SINGLE))))
                        vif.slv_cb.hreadyout <= $random;
                       
                     //Drive data when is NO ERROR
                     if(vif.slv_cb.hwrite == AHB_READ && vif.slv_cb.hreadyout && vif.slv_cb.htrans != BUSY)
                     begin
                        vif.slv_cb.hrdata <= trans.ahb_data[data_index];
                        data_index++;
                     end// Drive data when is NO ERROR
                  end //SINGLE, INCR3, WRAP4, INCR8, WRAP8, INCR16, WRAP16 CASES & NO ERROR
                 
                  @(vif.slv_cb);

               end //while
            end
      endcase  
   endtask: drive_ahb_trans
endclass:ahb_driver
`endif 