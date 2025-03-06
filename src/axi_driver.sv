//------------------------------------
// File name   : axi_driver.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_DRIVER_SV
`define AXI_DRIVER_SV
`include "axi_trans.sv"

class axi_driver #(AW=32,DW=32) extends uvm_driver #(axi_trans #(AW,DW));
   //MASTER or SLAVE
   axi_agent_kind_t agent_kind;
   
   
   int unsigned       number_of_write_transfers_outstanding; //from config
   int unsigned       number_of_read_transfers_outstanding;
   
   bit[3:0] read_ids [$];   //arid  collected on arvalid & arready
   bit[3:0] read_lengths[$];//arlen collected on arvalid & arready
   
   bit outstanding;

   //register with the factory 
      `uvm_component_utils_begin(axi_driver #(AW,DW))
      `uvm_field_int(number_of_write_transfers_outstanding, UVM_ALL_ON)
      `uvm_field_int(number_of_read_transfers_outstanding, UVM_ALL_ON)
      `uvm_field_int(outstanding, UVM_ALL_ON)
   `uvm_component_utils_end
   
   //axi interface
   virtual interface axi_if #(AW,DW) vif;
   
  mailbox #(axi_trans #(32, 32)) writeaddress_mbx  = new(0); 
  mailbox #(axi_trans #(32, 32)) writedata_mbx     = new(0);
  mailbox #(axi_trans #(32, 32)) writeresp_mbx     = new(0);
  mailbox #(axi_trans #(32, 32)) readaddress_mbx   = new(0);
  mailbox #(axi_trans #(32, 32)) readdata_mbx      = new(0);
  
   axi_trans #(32, 32) item;
  
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
     @(negedge vif.aresetn or posedge vif.aresetn);
     forever
     begin
        while($isunknown(vif.aresetn) || vif.aresetn === 1'b0) //reset is x, z or 0
        begin
           drive_reset_values(); //drive reset values
           @(vif.mst_cb);
        end
        
     begin 
          fork
            drive_write_address_channel();
            drive_write_data_channel();
            drive_write_response_channel();
            drive_read_address_channel();
            drive_read_data_channel();
          join_none

          //get item from sequencer and send it to addres channel by type : READ or WRITE
          forever begin
            seq_item_port.get(item);
            //`uvm_info(this.get_type_name(),$sformatf("Item: %s", item.sprint()), UVM_INFO)
           // `uvm_info(this.get_type_name(),$sformatf("outstanding config %d %d ", outstanding, number_of_write_transfers_outstanding), UVM_INFO)
            case (item.axi_op_type)
              AXI_WRITE : begin
                writeaddress_mbx.put(item);
            end
              AXI_READ  : begin
                readaddress_mbx.put(item);
              end
            endcase
          end
        end
 
     end
   endtask:run_phase
   
   
   task drive_write_address_channel();
      if(agent_kind==AXI_MASTER) begin
        axi_trans #(32, 32) item =null;
        axi_trans #(32, 32) item1;
        int id[$];
        int delay;
        fork
          forever begin
             if (vif.mst_cb.awready && vif.mst_cb.awvalid) begin
              id.push_back(vif.mst_cb.awid);
             end
             if (vif.mst_cb.bready && vif.mst_cb.bvalid) begin
              id.pop_front();
             end
             @vif.mst_cb;
          end
          forever begin
            if(id.size == number_of_write_transfers_outstanding) //if the resp for packets didn't come -> wait
            begin 
              vif.mst_cb.awvalid <= 'b0;
              //`uvm_info(this.get_type_name(),$sformatf("Wait write response, max outstanding in process %d ", number_of_write_transfers_outstanding), UVM_INFO)
              @vif.mst_cb;
            end
            else begin
              if (item == null) begin
                writeaddress_mbx.get(item);
             // `uvm_info(this.get_type_name(),$sformatf("Item: %s", item.sprint()),UVM_HIGH)
              end

              @(vif.mst_cb);

              if (vif.mst_cb.awready && vif.mst_cb.awvalid) begin
                writedata_mbx.put(item);//send to data channel
                writeresp_mbx.put(item);//send to response channel
                item1 = item;
                delay= item.delay_between_addr;
                item = null; 

              //if item back to back prepare next item (get item from sequencer)
                if (delay==0) begin
                  if (writeaddress_mbx.try_get(item)) begin
                   // `uvm_info(this.get_type_name(),$sformatf("Item try: %s", item.sprint()), UVM_HIGH)
                  end
                end
              end
            
              if (item != null) begin  
                delay= item.delay_between_addr;
                vif.mst_cb.awvalid <= 'b1;
                vif.mst_cb.awid    <= item.axi_id;
                vif.mst_cb.awaddr  <= item.axi_start_addr;
                vif.mst_cb.awlen   <= item.axi_length;
                vif.mst_cb.awsize  <= item.axi_size_type;
                vif.mst_cb.awburst <= item.axi_burst_type;
              end
              
              else begin   
                if (delay> 0) begin
                  vif.mst_cb.awvalid <= 'b0;
                  vif.mst_cb.awid    <= 'b0;
                  vif.mst_cb.awaddr  <= 'b0;
                  vif.mst_cb.awlen   <= 'b0;
                  vif.mst_cb.awsize  <= 'b0;
                  vif.mst_cb.awburst <= 'b0;
                  repeat(delay-1) @(vif.mst_cb);
                end
              end//else
          end
        end // forever
      join_none
   end
   else 
   begin
     forever begin
       vif.slv_cb.awready <= $random;
       @(vif.slv_cb);
     end
   end
 endtask : drive_write_address_channel


    task drive_read_address_channel();
      if(agent_kind==AXI_MASTER) begin
      axi_trans #(32, 32) item =null;
      axi_trans #(32, 32) item1;
      int id[$];
      int delay;
      fork
        forever begin
            if (vif.mst_cb.arready && vif.mst_cb.arvalid) begin
              id.push_back(vif.mst_cb.arid);
             end
             if (vif.mst_cb.rready && vif.mst_cb.rlast && vif.mst_cb.rvalid) begin
              id.pop_front();
             end
             @vif.mst_cb;
        end
        forever begin
          if(id.size == number_of_read_transfers_outstanding)begin //if resp didn't come for x transfers-> wait
            vif.mst_cb.arvalid <= 'b0;
            `uvm_info(this.get_type_name(),$sformatf("Wait read response, max outstanding in process"), UVM_INFO)
            @vif.mst_cb;
          end
          else begin
              if (item == null) begin
                readaddress_mbx.get(item); //get item from sequencer
              //`uvm_info(this.get_type_name(),$sformatf("Item: %s", item.sprint()),UVM_HIGH)
              end

              @(vif.mst_cb);

              if (vif.mst_cb.arready && vif.mst_cb.arvalid) begin
                readdata_mbx.put(item);//put item for read data channel
                item1 = item;
                delay= item.delay_between_addr;
                item = null; 

              // @(vif.mst_cb);
                if (delay==0) begin //prepare next item if back2back
                  if (readaddress_mbx.try_get(item)) begin
                   // `uvm_info(this.get_type_name(),$sformatf("Item: %s", item.sprint()), UVM_HIGH)
                  end
                end
              end

              if (item != null) begin  
                delay= item.delay_between_addr;
                vif.mst_cb.arvalid <= 'b1;
                vif.mst_cb.arid    <= item.axi_id;
                vif.mst_cb.araddr  <= item.axi_start_addr;
                vif.mst_cb.arlen   <= item.axi_length;
                vif.mst_cb.arsize  <= item.axi_size_type;
                vif.mst_cb.arburst <= item.axi_burst_type;
                read_ids.push_back(vif.mst_cb.arid);
                read_lengths.push_back(vif.mst_cb.arlen);
              end
              
            else begin   
              if (delay> 0) begin
                vif.mst_cb.arvalid <= 'b0;
                vif.mst_cb.arid    <= 'b0;
                vif.mst_cb.araddr  <= 'b0;
                vif.mst_cb.arlen   <= 'b0;
                vif.mst_cb.arsize  <= 'b0;
                vif.mst_cb.arburst <= 'b0;
                repeat(delay-1) @(vif.mst_cb);
              end
            end//else
            end
      end // forever
     join_none
    end
    else 
    begin
      forever begin
        vif.slv_cb.arready <= $random;
        @(vif.slv_cb);
      end
    end
 endtask : drive_read_address_channel
 
  task drive_write_data_channel();
    if(agent_kind==AXI_MASTER) begin
      axi_trans #(32, 32) item  = null;
      axi_trans #(32, 32) item1;

      int delay;
      
      forever begin

        if (item == null) begin
          writedata_mbx.get(item); //get item from address 
          //`uvm_info(this.get_type_name(),$sformatf("Item: %s", item.sprint()),UVM_HIGH)
        end

          if (vif.mst_cb.wready && vif.mst_cb.wvalid) begin
              //item1 = item;
              delay= item.delay_between_data;

              if (delay==0) begin //if back2back prepare next item
                // if not, check if there's another item
                if (writedata_mbx.try_get(item1)) begin
                       // `uvm_info(this.get_type_name(),$sformatf("Item: %s", item.sprint()), UVM_HIGH)

                end
            end
          end
        
          if (item != null) begin   //put data and strobe
          delay= item.delay_between_data;
            vif.mst_cb.wvalid <= 'b1;
            vif.mst_cb.wlast  <= 'b0;
            vif.mst_cb.wstrb  <= item.axi_wstrobe;

              for(int i=0;i<item.axi_data.size-1;i++)begin
              vif.mst_cb.wdata  <= item.axi_data[i];
                @(vif.mst_cb iff vif.mst_cb.wready); 
              end
                vif.mst_cb.wdata   <= item.axi_data[item.axi_data.size-1];
                  vif.mst_cb.wlast <= 'b1;
                @(vif.mst_cb iff vif.mst_cb.wready); 
                item.axi_data.delete();
                vif.mst_cb.wvalid <= 'b0;
                vif.mst_cb.wdata  <= 'b0;
                vif.mst_cb.wlast  <= 'b0;
                vif.mst_cb.wstrb  <= 'b0;
            if(item1) begin 
              item =item1;
              item1=null;
            end
            else 
              item = null;
          end 
        else begin   
          if (delay> 0) begin
            vif.mst_cb.wvalid <= 'b0;
            vif.mst_cb.wdata  <= 'b0;
            vif.mst_cb.wlast  <= 'b0;
            vif.mst_cb.wstrb  <= 'b0;

              repeat(delay) @(vif.mst_cb);
            end
      end
          if (delay> 0) begin
            vif.mst_cb.wvalid <= 'b0;
            vif.mst_cb.wdata  <= 'b0;
            vif.mst_cb.wlast  <= 'b0;
            vif.mst_cb.wstrb  <= 'b0;
              repeat(delay) @(vif.mst_cb);
            end
        end // forever
    end
    else begin
      forever begin
        vif.slv_cb.wready <= $random;
        @(vif.slv_cb);
      end
    end
 endtask : drive_write_data_channel


  task drive_read_data_channel();
    if(agent_kind==AXI_SLAVE) begin
      int number_data [$];
        int pending_ids [$][$];
      int id [$];
      int n = 0; 
      int resp_index;
      
      for (int i=0;i<16;i++)
      number_data[i] =0;
     for (int i=0;i<16;i++)
      pending_ids[i] = {};
     
       fork 
            forever begin
              @(vif.slv_cb iff (vif.slv_cb.arready && vif.slv_cb.arvalid)); 
                //number_data.push_back(vif.slv_cb.arlen + 1);
                if(number_data[vif.slv_cb.arid] != 0)begin
                  pending_ids[vif.slv_cb.arid].push_back(vif.slv_cb.arlen + 1); //colects arid 
                    // $display("pending_ids[n].size --  %d ",  pending_ids[vif.slv_cb.arid].size );
                  // $display("switch pending --  %d ",  number_data[vif.slv_cb.arid] );
                  //$display("pending --  %d ",  vif.slv_cb.arid );
                end
                else begin
                  number_data[vif.slv_cb.arid] = vif.slv_cb.arlen + 1; //collectes arlen 
                     // $display("no pending --  %d ",  number_data[vif.slv_cb.arid] );
                end
                id.push_back(vif.slv_cb.arid);
               id.shuffle();
                //$display("number_data  %d ", number_data[vif.slv_cb.arid] );
            end
            forever begin
            if(id.size() != 0) begin 
              id.shuffle(); //for interleaving
               resp_index = $urandom_range(0,(number_data[id[0]]-1)); //where to generate resp
               @(vif.slv_cb);
               vif.slv_cb.rvalid <= 'b1;
               vif.slv_cb.rdata  <= $random;
               vif.slv_cb.rid    <= id[0];
               number_data[id[0]] = number_data[id[0]] -1;
               if(number_data[id[0]] == resp_index) vif.slv_cb.rresp <= $urandom_range(0,3);
               else vif.slv_cb.rresp  <= 'b0;
                //$display("number_data --  %d ",  number_data[id[0]] );
               if(number_data[id[0]]==0) begin //decide if last data based on arlen and arid
                  vif.slv_cb.rlast <= 'b1;
                   n=id.pop_front();
                   if(pending_ids[n].size) number_data[n] = pending_ids[n].pop_front();
                   // $display("pending_ids[n].size --  %d ",  pending_ids[n].size );
                  // $display("switch pending --  %d ",  number_data[n] );
                  
                 
               end 
               @(vif.slv_cb iff vif.slv_cb.rready);
            end
                vif.slv_cb.rvalid <= 'b0;
                vif.slv_cb.rdata  <= 'h0;
                vif.slv_cb.rlast  <= 'b0;
                vif.slv_cb.rresp  <= 'b0;
              @(vif.slv_cb );
            end
        join_none
    end
    else begin //rready generation
        axi_trans #(32, 32) item ;
        int pattern ;
        fork
          forever begin
            readdata_mbx.get(item);
            pattern = item.rready_pattern;
          end
          forever begin
            if(pattern == ALWAYS_1)
              vif.mst_cb.rready <= 'b1;
            else if(pattern == TOGGLE_1)
                    vif.mst_cb.rready<= ~vif.mst_cb.rready;
                  else if(pattern == RANDOM)
                        vif.mst_cb.rready<= $random;
            @(vif.mst_cb);
        end
      join_none
    end
 endtask : drive_read_data_channel

 
 task drive_write_response_channel();
   if(agent_kind == AXI_MASTER)     
   begin
        axi_trans #(32, 32) item ;
        int pattern ;
        fork //bready generation
          forever begin
            writeresp_mbx.get(item);
            pattern = item.bready_pattern;
          end
          forever begin
            if(pattern == ALWAYS_1)
              vif.mst_cb.bready <= 'b1;
            else if(pattern == TOGGLE_1)
                    vif.mst_cb.bready<= ~vif.mst_cb.bready;
                  else if(pattern == RANDOM)
                        vif.mst_cb.bready<= $random;
            @(vif.mst_cb);
        end
      join_none
    end//MASTER
   else
  begin
   int index=0;
   int id [$];
   int id_clone [$];
   int found =0;
   fork
      forever begin
         @(vif.slv_cb iff (vif.slv_cb.awready && vif.slv_cb.awvalid)); //collects awid
         id.push_back( vif.slv_cb.awid);
         //id[vif.slv_cb.awid] =0;
      end
      forever begin
         @(vif.slv_cb iff (vif.slv_cb.wready && vif.slv_cb.wvalid && vif.slv_cb.wlast)); //which awid is finished on write data so we can put bresp
         id_clone.push_back(id.pop_front());
      end 

      forever begin
         if(outstanding) begin //outstaning - bit config for slave to know if we want outstanting bresp
         for(int i=0;i<number_of_write_transfers_outstanding && ~found ;i++)begin
          @(vif.slv_cb iff (vif.slv_cb.wready && vif.slv_cb.wvalid && vif.slv_cb.wlast)); //collects ids to have data to shuffle
          end
          found =1;
          end 
          else  @(vif.slv_cb iff (vif.slv_cb.wready && vif.slv_cb.wvalid && vif.slv_cb.wlast)); 
         forever begin 
         if(id_clone.size>number_of_write_transfers_outstanding-1)begin //put resp
           vif.slv_cb.bvalid <= 'b1;
           index = $urandom_range (0,(id_clone.size-1));
           vif.slv_cb.bid    <= id_clone[index];
           vif.slv_cb.bresp  <= $urandom_range(0,3);
           id_clone.delete(index);
           @(vif.slv_cb iff vif.slv_cb.bready );
           vif.slv_cb.bvalid <= 'b0;
           vif.slv_cb.bid    <= 'h0;
           vif.slv_cb.bresp  <= 'b0;
         end
         else if(id_clone.size)begin
           vif.slv_cb.bvalid <= 'b1;
           index = $urandom_range (0,(id_clone.size-1));
           vif.slv_cb.bid    <= id_clone[index];
           vif.slv_cb.bresp  <= $urandom_range(0,3);
           id_clone.delete(index);
           @(vif.slv_cb iff vif.slv_cb.bready );
           vif.slv_cb.bvalid <= 'b0;
           vif.slv_cb.bid    <= 'h0;
           vif.slv_cb.bresp  <= 'b0;
         end
         @(vif.slv_cb);
         end
         @(vif.slv_cb);
      end
     join_none
   end
 endtask : drive_write_response_channel


 //idle values for driven signals
   task drive_reset_values();
     case (agent_kind)
      AXI_MASTER: begin
         vif.mst_cb.awvalid <= 'b0;
         vif.mst_cb.awid    <= 'b0;
         vif.mst_cb.awaddr  <= 'b0;
         vif.mst_cb.awlen   <= 'b0;
         vif.mst_cb.awsize  <= 'b0;
         vif.mst_cb.awburst <= 'b0;
         vif.mst_cb.wvalid  <= 'b0;
         vif.mst_cb.wdata   <= 'b0;
         vif.mst_cb.wstrb   <= 'b0;
         vif.mst_cb.wlast   <= 'b0;
         vif.mst_cb.bready  <= 'b0;
         vif.mst_cb.arvalid <= 'b0;
         vif.mst_cb.arid    <= 'b0;
         vif.mst_cb.araddr  <= 'b0;
         vif.mst_cb.arlen   <= 'b0;
         vif.mst_cb.arsize  <= 'b0;
         vif.mst_cb.arburst <= 'b0;
         vif.mst_cb.rready  <= 'b0;
         vif.mst_cb.awlock  <= 'b0;
         vif.mst_cb.arlock  <= 'b0;
         vif.mst_cb.awcache <= 'b0;
         vif.mst_cb.arcache <= 'b0;
         vif.mst_cb.awprot  <= 'b0;
         vif.mst_cb.arprot  <= 'b0;
       end
       AXI_SLAVE: begin
         vif.slv_cb.awready <= 'b1;
         vif.slv_cb.wready  <= 'b0;
         vif.slv_cb.bvalid  <= 'b0;
         vif.slv_cb.bid     <= 'b0;
         vif.slv_cb.bresp   <= 'b0;
         vif.slv_cb.arready <= 'b0;
         vif.slv_cb.rvalid  <= 'b0;
         vif.slv_cb.rdata   <= 'b0;
         vif.slv_cb.rlast   <= 'b0;
         vif.slv_cb.rid     <= 'b0;
         vif.slv_cb.rresp   <= 'b0;
       end
     endcase
   endtask:drive_reset_values

   

endclass:axi_driver
`endif 