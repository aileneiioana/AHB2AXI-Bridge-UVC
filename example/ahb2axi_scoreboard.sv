//------------------------------------
// File name   : axi_env.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB2AXI_SCOREBOARD_SV
`define AHB2AXI_SCOREBOARD_SV

`include "axi_trans.sv"
`include "ahb_trans.sv"
`uvm_analysis_imp_decl(_ahb_master) // uvm_macro to declare an analysis import
`uvm_analysis_imp_decl(_axi_slave)  // uvm_macro to declare an analysis import

class ahb2axi_scoreboard #(AW=32,DW=32) extends uvm_scoreboard;

  uvm_analysis_imp_ahb_master #(ahb_trans#(32, 32), ahb2axi_scoreboard) master_export;
  uvm_analysis_imp_axi_slave  #(axi_trans#(32, 32), ahb2axi_scoreboard) slave_export;
  
  bit has_checks  ; // global checkers enable
  bit has_coverage; // global coverage enable

  protected ahb_trans#(32, 32) master_trans;
  protected axi_trans#(32, 32) slave_trans;
  
  ahb_trans#(32, 32)  master_transfers [$];
  axi_trans#(32, 32)  write_slave_transfers  [$];
  axi_trans#(32, 32)  read_slave_transfers  [$];
  
  int  slave_transfers1  [$];
  
  bit[31:0] ctrl_value  =0 ;
  
  bit[31:0] adress_space ;
  
  event ctrl_cov_e       ;
  event adress_space_cg_e;  

  int unsigned       number_of_write_transfers_outstanding; //from config
  int unsigned       number_of_read_transfers_outstanding;
   
  bit outstanding;
  
  int unsigned axlen;
   
  int unsigned expected_number_of_master_transfers, expected_number_of_slave_transfers, actual_number_of_master_transfers, actual_number_of_slave_transfers;
   
   `uvm_component_utils_begin(ahb2axi_scoreboard)
      `uvm_field_int(has_checks, UVM_ALL_ON)
      `uvm_field_int(has_coverage, UVM_ALL_ON)
      `uvm_field_int(number_of_write_transfers_outstanding, UVM_ALL_ON)
      `uvm_field_int(number_of_read_transfers_outstanding, UVM_ALL_ON)
      `uvm_field_int(outstanding, UVM_ALL_ON)
   `uvm_component_utils_end

   
  covergroup ctrl_cov @(ctrl_cov_e);
     wrap_value_c            : coverpoint ctrl_value[1];
     outstanding_value_c     : coverpoint ctrl_value[0];
     max_outstandung_value_c : coverpoint ctrl_value[13:8]{
                                    bins max_outstandung_4  = {4};
                                    bins max_outstandung_8  = {8};
                                    bins max_outstandung_16 = {16};
                                    bins max_outstandung_32 = {32};
                                    }    
     reserved1_value_c       : coverpoint ctrl_value[7:2]{
                                    bins zero = {0};
                                    }   
     reserved2_value_c       : coverpoint ctrl_value[31:14]{
                                    bins zero1= {0};
                                    }    
     outstanding_cp: cross outstanding_value_c, max_outstandung_value_c{
                             ignore_bins xy1 = binsof(outstanding_value_c)  intersect {0};
                             }
     wrap_en_outstanding_cp: cross wrap_value_c, outstanding_cp;
     
     reserved_cp:    cross reserved1_value_c, reserved2_value_c{
                             illegal_bins xy2 = binsof(reserved1_value_c)  intersect {[1:31]};
                             illegal_bins xy3 = binsof(reserved2_value_c)  intersect {[1:131071]};
                                    }     
   endgroup
   
     covergroup adress_space_cg @(adress_space_cg_e);
                          
     incr4_addr_split_c       : coverpoint master_trans.start_addr[11:0] {
                                    bins incr4_cycles0  = {'d4092};
                                    bins incr4_cycles1  = {'d4088};
                                    bins incr4_cycles2  = {'d4084};
                                    bins incr4_cycles3  = {'d4080};
                                    }
     incr8_addr_split_c       : coverpoint master_trans.start_addr[11:0] {
                                    bins incr8_cycles0  = {'d4092};
                                    bins incr8_cycles1  = {'d4088};
                                    bins incr8_cycles2  = {'d4084};
                                    bins incr8_cycles3  = {'d4080};
                                    bins incr8_cycles4  = {'d4076};
                                    bins incr8_cycles5  = {'d4072};
                                    bins incr8_cycles6  = {'d4068};
                                    bins incr8_cycles7  = {'d4064};
                                    }
     incr16_addr_split_c      : coverpoint master_trans.start_addr[11:0] {
                                    bins incr16_cycles0   = {4092};
                                    bins incr16_cycles1   = {4088};
                                    bins incr16_cycles2   = {4084};
                                    bins incr16_cycles3   = {4080};
                                    bins incr16_cycles4   = {4076};
                                    bins incr16_cycles5   = {4072};
                                    bins incr16_cycles6   = {4068};
                                    bins incr16_cycles7   = {4064};
                                    bins incr16_cycles8   = {4060};
                                    bins incr16_cycles9   = {4056};
                                    bins incr16_cycles10  = {4052};
                                    bins incr16_cycles11  = {4048};
                                    bins incr16_cycles12  = {4044};
                                    bins incr16_cycles13  = {4040};
                                    bins incr16_cycles14  = {4036};
                                    bins incr16_cycles15  = {4032};
                                    }
                                    
     burst_c            : coverpoint master_trans.ahb_burst_type;
    
     incr4_SPLIT_cp           : cross incr4_addr_split_c,  burst_c{ignore_bins split_incr4 = binsof(burst_c) intersect {SINGLE, WRAP4, INCR8, INCR16, WRAP8,WRAP16};}
     incr8_SPLIT_cp           : cross incr8_addr_split_c,  burst_c{ignore_bins split_incr8 = binsof(burst_c) intersect {SINGLE, WRAP4, INCR4, INCR16, WRAP8,WRAP16};}
     incr16_SPLIT_cp          : cross incr16_addr_split_c, burst_c{ignore_bins split_incr16 = binsof(burst_c) intersect {SINGLE, WRAP4, INCR8, INCR4, WRAP8,WRAP16};}
   
                      
     data_space               : coverpoint adress_space{
                                    bins int_val1  = {['h1000_0001:'h1FFF_FFFF]};
                                    bins int_val2  = {['h2000_0001:'h2FFF_FFFF]};
                                    bins int_val3  = {['h3000_0001:'h3FFF_FFFF]};
                                    bins int_val4  = {['h4000_0001:'h4FFF_FFFF]};
                                    bins int_val5  = {['h5000_0001:'h5FFF_FFFF]};
                                    bins int_val6  = {['h6000_0001:'h6FFF_FFFF]};
                                    bins int_val7  = {['h7000_0001:'h7FFF_FFFF]};
                                    bins int_val8  = {['h8000_0001:'h8FFF_FFFF]};
                                    bins int_val9  = {['h9000_0001:'h9FFF_FFFF]};
                                    bins int_valA  = {['hA000_0001:'hAFFF_FFFF]};
                                    bins int_valB  = {['hB000_0001:'hBFFF_FFFF]};
                                    bins int_valC  = {['hC000_0001:'hCFFF_FFFF]};
                                    bins int_valD  = {['hD000_0001:'hDFFF_FFFF]};
                                    bins int_valE  = {['hE000_0001:'hEFFF_FFFF]};
                                    bins int_valF  = {['hF000_0001:'hFFFF_FFFE]};
                                    }    
     endgroup
      
   covergroup adress_space_toggle_cov with function sample_adress_space(bit[DW-1:0] data, int pos);
     toggle_adress_space : coverpoint data[pos] {  
                                            bins zeroone = (0 => 1);
                                            bins onezero = (1 => 0);
                                          }
   endgroup

   function void sample_adress_space(bit[DW-1:0] data);
      for(int i = 0; i < DW; i++) begin
        adress_space_toggle_cov.sample(data, i);
      end
   endfunction
  
  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent); 
    // get `has_coverage from db
     uvm_config_db#(int)::get(this, "", "has_coverage", has_coverage);
      // get `has_checks from db
     uvm_config_db#(int)::get(this, "", "has_checks", has_checks);
          uvm_config_db#(int)::get(this, "", "number_of_write_transfers_outstanding", number_of_write_transfers_outstanding);
          uvm_config_db#(int)::get(this, "", "number_of_read_transfers_outstanding", number_of_read_transfers_outstanding);
          uvm_config_db#(int)::get(this, "", "outstanding", outstanding);
 
        // `uvm_info(get_type_name(), $sformatf("cov %d",has_coverage), UVM_LOW)
     // if (has_coverage) 
     // begin
        ctrl_cov                = new;
        adress_space_cg         = new;
        adress_space_toggle_cov = new;
     // end
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_export = new("master_export", this);
    slave_export = new("slave_export", this);
    
  endfunction: build_phase
  
    function void write_ahb_master(input ahb_trans#(32, 32) item);
        $cast(master_trans,item);
        master_transfers.push_back(master_trans);
        if(master_trans.start_addr == 'h100 ) begin 
           if(master_trans.ahb_wstrobe == 'hF && master_trans.ahb_op_type == AHB_WRITE) ctrl_value = master_trans.ahb_data[0];
          else if( master_trans.ahb_wstrobe == 'h1 && master_trans.ahb_op_type == AHB_WRITE) ctrl_value[7:0]   = master_trans.ahb_data[0][7:0] ;
          else if( master_trans.ahb_wstrobe == 'h2 && master_trans.ahb_op_type == AHB_WRITE) ctrl_value[15:8]  = master_trans.ahb_data[0][15:8];
          else if( master_trans.ahb_wstrobe == 'h4 && master_trans.ahb_op_type == AHB_WRITE) ctrl_value[23:16] = master_trans.ahb_data[0][23:16] ;
          else if( master_trans.ahb_wstrobe == 'h8 && master_trans.ahb_op_type == AHB_WRITE) ctrl_value[31:24] = master_trans.ahb_data[0][31:24] ;
          else if( master_trans.ahb_wstrobe == 'h3 && master_trans.ahb_op_type == AHB_WRITE) ctrl_value[15:0]  = master_trans.ahb_data[0][15:0] ;
          else if( master_trans.ahb_wstrobe == 'hC && master_trans.ahb_op_type == AHB_WRITE) ctrl_value[31:16] = master_trans.ahb_data[0][31:16]; 
            ->ctrl_cov_e;
            ->adress_space_cg_e;
        end
        else begin 
          adress_space= master_trans.start_addr;
          ->adress_space_cg_e;
          this.sample_adress_space(adress_space);
        end
      //   `uvm_info(get_type_name(), $sformatf("The Scoreboard received this MASTER master_transfer:\n%s",master_trans.sprint()), UVM_LOW)
    endfunction
    
    function void write_axi_slave(input axi_trans#(32, 32) item);
        $cast(slave_trans,item);
        ->ctrl_cov_e;
        if(slave_trans.axi_op_type == AXI_WRITE)
          write_slave_transfers.push_back(slave_trans);
        else 
          read_slave_transfers.push_back(slave_trans);
      //   `uvm_info(get_type_name(), $sformatf("The Scoreboard received this SLAVE master_transfer:\n%s",slave_trans.sprint()), UVM_LOW)
    endfunction
    
  //check data integrity and ctrl info when wrap enabled
  function check_data_integrity_wrap (ahb_trans#(32, 32) item1, axi_trans#(32, 32) item2);
  //`uvm_info(this.get_type_name(),$sformatf("scoreboard outstanding config %d %d ",outstanding, number_of_write_transfers_outstanding), UVM_INFO)
   if(((item1.ahb_op_type == AHB_WRITE) && (item2.axi_op_type != AXI_WRITE)) || ((item1.ahb_op_type != AHB_WRITE) && (item2.axi_op_type == AXI_WRITE)))begin
     uvm_report_error("SCOREBOARD Op type not the same" , "Master Monitor sent different operation than Slave Monitor" );
    `uvm_info(get_type_name(), $sformatf("item1.ahb_op_type %d item2.axi_op_type %d axi_id %d",item1.ahb_op_type, item2.axi_op_type, item2.axi_id), UVM_LOW)
      end
      //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
    if(item1.ahb_size_type != item2.axi_size_type)begin 
      uvm_report_error("SCOREBOARD SIZE not the same" , "Master Monitor sent different size type than Slave Monitor" );
     `uvm_info(get_type_name(), $sformatf("item1.ahb_size_type %d item2.axi_size_type %d",item1.ahb_size_type, item2.axi_size_type), UVM_LOW)
    end
    //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW);
    if(item1.ahb_burst_type == SINGLE && item2.axi_length != 0 && item1.ahb_data.size()!=1)
      uvm_report_error("SCOREBOARD Length not the same" , "Master Monitor sent different number of data than Slave Monitor" );
    //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
    if((item1.ahb_burst_type == INCR4  || item1.ahb_burst_type == WRAP4)  && (item2.axi_length != 3 || item1.ahb_data.size()!=4))
      uvm_report_error("SCOREBOARD Length not the same" , "Master Monitor sent different number of data than Slave Monitor" ); 
    //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
    if((item1.ahb_burst_type == INCR8  || item1.ahb_burst_type == WRAP8)  && (item2.axi_length != 7 || item1.ahb_data.size()!=8))
      uvm_report_error("SCOREBOARD Length not the same" , "Master Monitor sent different number of data than Slave Monitor" );
    //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
    if((item1.ahb_burst_type == INCR16  || item1.ahb_burst_type == WRAP16)  && (item2.axi_length != 15 || item1.ahb_data.size()!=16))
      uvm_report_error("SCOREBOARD Length not the same" , "Master Monitor sent different number of data than Slave Monitor" );
    //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
    if((item1.ahb_burst_type == INCR4 ||  item1.ahb_burst_type == INCR8 ||item1.ahb_burst_type == INCR16) && (item2.axi_burst_type != 'b01))
      uvm_report_error("SCOREBOARD Burst not the same" , "Master Monitor sent different burst type than Slave Monitor" );
    if((item1.ahb_burst_type == WRAP4 ||  item1.ahb_burst_type == WRAP8 ||item1.ahb_burst_type == WRAP16) && (item2.axi_burst_type != 'b10))
      uvm_report_error("SCOREBOARD Burst not the same" , "Master Monitor sent different burst type than Slave Monitor" );
    if((item1.ahb_burst_type == SINGLE) && (item2.axi_burst_type != 'b00))
      uvm_report_error("SCOREBOARD Burst not the same" , "Master Monitor sent different burst type than Slave Monitor" ); 
    if((item1.ahb_wstrobe != item2.axi_wstrobe) && item1.ahb_op_type ==AHB_WRITE)begin
      uvm_report_error("SCOREBOARD Strobe not the same" , "Master Monitor sent different wstrobe type than Slave Monitor" ); 
      `uvm_info(get_type_name(), $sformatf("item1.ahb_wstrobe %h item2.axi_wstrobe %h axi_id %d",item1.ahb_wstrobe, item2.axi_wstrobe, item2.axi_id), UVM_LOW)
      end
    if((item1.ahb_hresp=='b1 && (item2.axi_resp != AXI_DECERR && item2.axi_resp != AXI_SLVERR)) && item1.ahb_op_type ==AHB_READ )begin
      uvm_report_error("SCOREBOARD Read Response not the same" , "Master Monitor sent different resp type than Slave Monitor " ); 
      `uvm_info(get_type_name(), $sformatf("item1.ahb_hresp %h item2.axi_resp %h axi_id %d",item1.ahb_hresp, item2.axi_resp, item2.axi_id), UVM_LOW)
    end
      //`uvm_info(get_type_name(), $sformatf(" item1.ahb_data.size %d item2.axi_data.size %d ",item1.ahb_data.size(), item2.axi_data.size()), UVM_LOW)
    foreach(item2.axi_data[i])begin
      if(item1.ahb_data[i] != item2.axi_data[i]) begin
        uvm_report_error("SCOREBOARD Data not the same" , "Master Monitor sent different data than Slave Monitor" );
       `uvm_info(get_type_name(), $sformatf("item1.ahb_data[i] %h item2.axi_data[i] %h axi_id %d i %d ",item1.ahb_data[i], item2.axi_data[i], item2.axi_id, i), UVM_LOW)
        end
      //else `uvm_info(get_type_name(), $sformatf("good item1.ahb_data[i] %h item2.axi_data[i] %h axi_id %d i %d",item1.ahb_data[i], item2.axi_data[i], item2.axi_id, i), UVM_LOW)
    end
  endfunction
  
  bit[31:0] addr_low;   //lowest address in wrap burst
  bit[31:0] ahb_addr [$];//ahb adress queue
  int wrap_position = 0; //position of lowest addr
  int i,j; //counters for data wrap
  
  //check data integrity and ctrl info when wrap is not enabled
  function check_data_integrity_no_wrap (ahb_trans#(32, 32) item1, axi_trans#(32, 32) item2, bit[31:0] addr_low);
   ->adress_space_cg_e;
    ahb_addr[0] = master_trans.start_addr;
    //create ahb addr queue using start_addr 
    if(master_trans.ahb_burst_type == INCR4 || master_trans.ahb_burst_type == WRAP4) 
         for(int i=0;i<4;i++ )
           ahb_addr.push_back(0);
       else
       if(master_trans.ahb_burst_type == INCR8 || master_trans.ahb_burst_type == WRAP8) 
          for(int i=0;i<8;i++ )
            ahb_addr.push_back(0);
       else
       if(master_trans.ahb_burst_type == INCR16 || master_trans.ahb_burst_type == WRAP16)
         for(int i=0;i<16;i++ )
           ahb_addr.push_back(0);
       else
       if(master_trans.ahb_burst_type == SINGLE)  
         ahb_addr.push_back(0);
                         
     if( master_trans.ahb_burst_type == INCR4 ||  master_trans.ahb_burst_type == INCR8 ||  master_trans.ahb_burst_type == INCR16)
         foreach(ahb_addr[i])
           if(i > 0)
             ahb_addr[i] = ahb_addr[i-1] + 2** master_trans.ahb_size_type;
           if((item1.ahb_burst_type == WRAP4) && (item1.ahb_size_type == 'b10))
              foreach (ahb_addr[i])
                if(i != 0)
                  ahb_addr[i] = ((((ahb_addr[i-1][3:2]+1) & 32'h0000_0003)<<2) + (ahb_addr[i-1] & 32'hFFFF_FFF3));
            if((item1.ahb_burst_type == WRAP8) && (item1.ahb_size_type == 'b10))
              foreach (ahb_addr[i])
                if(i != 0)
                  ahb_addr[i] = ((((ahb_addr[i-1][4:2]+1) & 32'h0000_0007)<<2) + (ahb_addr[i-1] & 32'hFFFF_FFE3));
            if((item1.ahb_burst_type == WRAP16) && (item1.ahb_size_type == 'b10))
              foreach (ahb_addr[i])
                if(i != 0)
                  ahb_addr[i] = ((((ahb_addr[i-1][5:2]+1) & 32'h0000_000F)<<2) + (ahb_addr[i-1] & 32'hFFFF_FFC3));
                  
      //search for lowest address and save the position 
      foreach(ahb_addr[i])
        if(ahb_addr[i] == addr_low) wrap_position =i;
     //`uvm_info(get_type_name(), $sformatf("wrap_position %d addr_low %h, ahb_addr %h", wrap_position, addr_low, ahb_addr[0]), UVM_LOW) 
    
    // `uvm_info(get_type_name(), $sformatf("ahb_addr %h axi_addr%h", ahb_addr[0], item2.axi_start_addr), UVM_LOW) 
      j=0;
      //check data from lowest address to last address from ahb 
      for(i=wrap_position; i< item1.ahb_data.size();i++)begin
        if(item2.axi_data[j] != item1.ahb_data[i]) begin
          uvm_report_error("SCOREBOARD Data not the same" , "Master Monitor sent different data than Slave Monitor" );
         `uvm_info(get_type_name(), $sformatf("item1.ahb_data[i] %h item2.axi_data[j] %h axi_id %d     %d %d",item1.ahb_data[i], item2.axi_data[j], item2.axi_id,i,j), UVM_LOW)
        end
      //else `uvm_info(get_type_name(), $sformatf("done data %d %d", j, i), UVM_LOW) 
       j++;
      end
      //check data from first ahb addr to lowest addr
      for(i=0; i< wrap_position;i++)begin
        if(item2.axi_data[j] != item1.ahb_data[i]) begin
          uvm_report_error("SCOREBOARD Data not the same" , "Master Monitor sent different data than Slave Monitor" );
         `uvm_info(get_type_name(), $sformatf("item1.ahb_data[i] %h item2.axi_data[j] %h axi_id %d    %d %d",item1.ahb_data[i], item2.axi_data[j], item2.axi_id,i,j), UVM_LOW)
        end
        // else `uvm_info(get_type_name(), $sformatf("done data %d %d", j, i), UVM_LOW) 
        j++;
      end 
    
      //`uvm_info(get_type_name(), $sformatf("done check integrity"), UVM_LOW)
      //delete global variables
      wrap_position= 0;
      ahb_addr.delete();
      i=0;j=0;
      addr_low=0;
  endfunction
  
  //check data integrity and ctrl info if 4kb boundary is crossed
  function check_data_integrity_4kb_crossed (ahb_trans#(32, 32) item1, axi_trans#(32, 32) item2, axi_trans#(32, 32) item3);
    int unsigned len;
    int i=0,j=0;
    //calculate the first length -> second length is total length-axlen
    axlen = ((4096 - item1.start_addr[11:0])/4) -1;
   //  `uvm_info(get_type_name(), $sformatf("axlen %d %d %d %d",axlen, item1.ahb_data.size(), item2.axi_length, item3.axi_length), UVM_LOW)
    //len == total length (ahb transfer) or (first axi transfer + second axi transfer)
    if (item1.ahb_burst_type == INCR4 || item1.ahb_burst_type == WRAP4) len = 4;
    else if (item1.ahb_burst_type == INCR8 || item1.ahb_burst_type == WRAP8) len = 8;
    else if (item1.ahb_burst_type == INCR16 || item1.ahb_burst_type == WRAP16) len = 16;
    else if (item1.ahb_burst_type == SINGLE) len = 1;
    
    if(axlen!= item2.axi_length && axlen!= item3.axi_length) begin
      uvm_report_error("SCOREBOARD Length EROOR1" , "SPLIT not procceded corectlly" );
     `uvm_info(get_type_name(), $sformatf("axlen %d %d",axlen, item2.axi_length), UVM_LOW)
    end
    if(((len-1)-(axlen+1))!= item3.axi_length && ((len-1)-(axlen+1))!= item2.axi_length) begin
      uvm_report_error("SCOREBOARD Length EROOR2" , "SPLIT not procceded corectlly" );
     `uvm_info(get_type_name(), $sformatf("axlen %d %d %d ",len, (len-1)-(axlen+1), item3.axi_length), UVM_LOW)
    end
      if(((item1.ahb_op_type == AHB_WRITE) && (item2.axi_op_type != AXI_WRITE)) || ((item1.ahb_op_type != AHB_WRITE) && (item2.axi_op_type == AXI_WRITE)))begin
     uvm_report_error("SCOREBOARD Op type not the same" , "Master Monitor sent different operation than Slave Monitor" );
    `uvm_info(get_type_name(), $sformatf("item1.ahb_op_type %d item2.axi_op_type %d axi_id %d",item1.ahb_op_type, item2.axi_op_type, item2.axi_id), UVM_LOW)
      end
      //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
     if(((item3.axi_op_type == AXI_WRITE) && (item2.axi_op_type != AXI_WRITE)) || ((item3.axi_op_type != AHB_WRITE) && (item2.axi_op_type == AXI_WRITE)))begin
     uvm_report_error("SCOREBOARD Op type not the same" , "Master Monitor sent different operation than Slave Monitor" );
      `uvm_info(get_type_name(), $sformatf("item1.ahb_op_type %d item2.axi_op_type %d axi_id %d",item3.axi_op_type, item2.axi_op_type, item3.axi_id), UVM_LOW)
      end
      //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
    if(item1.ahb_size_type != item2.axi_size_type || item3.axi_size_type != item2.axi_size_type)begin 
      uvm_report_error("SCOREBOARD SIZE not the same" , "Master Monitor sent different size type than Slave Monitor" );
     `uvm_info(get_type_name(), $sformatf("item1.ahb_size_type %d item2.axi_size_type %d item3.axi_size_type %d",item1.ahb_size_type, item2.axi_size_type,item3.axi_size_type), UVM_LOW)
    end
    //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW);
 
    if((((item1.ahb_wstrobe != item2.axi_wstrobe) || (item3.axi_wstrobe != item2.axi_wstrobe))) && item1.ahb_op_type ==AHB_WRITE)begin
      uvm_report_error("SCOREBOARD Strobe not the same" , "Master Monitor sent different wstrobe type than Slave Monitor" ); 
      `uvm_info(get_type_name(), $sformatf("item1.ahb_wstrobe %h item2.axi_wstrobe %h  item3.axi_wstrobe %h axi_id %d axi_id %d",item1.ahb_wstrobe, item2.axi_wstrobe, item3.axi_wstrobe,item2.axi_id,item3.axi_id), UVM_LOW)
      end
    if((item1.ahb_hresp=='b1 && ((item2.axi_resp != AXI_DECERR && item2.axi_resp != AXI_SLVERR)&&(item3.axi_resp != AXI_DECERR && item3.axi_resp != AXI_SLVERR))) && item1.ahb_op_type ==AHB_READ )begin
      uvm_report_error("SCOREBOARD Read Response not the same" , "Master Monitor sent different resp type than Slave Monitor " ); 
      `uvm_info(get_type_name(), $sformatf("item1.ahb_hresp %h item2.axi_resp %h axi_id %d",item1.ahb_hresp, item2.axi_resp, item2.axi_id), UVM_LOW)
      end
    //data integrity 
    // first trasnfer is the smallest
    if(item2.axi_data.size <= item3.axi_data.size)begin
       //$display("(item2.axi_data.size <= item3.axi_data.size");
        //axlen is the smallest length calculated
        if(axlen<((len-1)-(axlen+1)))begin
          for( i=0;i<axlen+1;i++)
            if(item1.ahb_data[i] != item2.axi_data[i]) begin
              uvm_report_error("SCOREBOARD Data1 not the same" , "Master Monitor sent different data than Slave Monitor" );
             `uvm_info(get_type_name(), $sformatf("item1.ahb_adr[i] %h item2.axi_adr[i] %h item3.axi_adr[i] %h item1.ahb_data[i] %h item2.axi_data[i] %h i %d j %d axi_id %d",item1.start_addr, item2.axi_start_addr, item3.axi_start_addr,item1.ahb_data[i], item2.axi_data[i],i,j, item2.axi_id), UVM_LOW)
            end
          //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
           for( i=axlen+1;i<len;i++)begin
             if(item1.ahb_data[i] != item3.axi_data[j]) begin
               uvm_report_error("SCOREBOARD Data2 not the same" , "Master Monitor sent different data than Slave Monitor" );
              `uvm_info(get_type_name(), $sformatf("item1.ahb_adr[i] %h item2.axi_adr[i] %h item3.axi_adr[i] %h item1.ahb_data[i] %h item2.axi_data[i] %h  i %d j %d  axi_id %d",item1.start_addr, item2.axi_start_addr, item3.axi_start_addr,item1.ahb_data[i], item2.axi_data[i], i,j,item3.axi_id), UVM_LOW)
             end
           //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
             j++;
           end
           
           if((item1.start_addr != item2.axi_start_addr) || ((item2.axi_start_addr + (axlen+1)*4 )!= item3.axi_start_addr) )begin
             uvm_report_error("SCOREBOARD ADDRESS not the same" , "Master Monitor sent different addr than Slave Monitor" );
            `uvm_info(get_type_name(), $sformatf("item1.ahb_addr %h item2.axi_addr %h item3.axi_addr %h axi_id %d, axi_id %d",item1.start_addr,item2.axi_start_addr, item3.axi_start_addr,item2.axi_id,  item3.axi_id), UVM_LOW)
           end
        end
        ////axlen is the bigest length calculated
        else begin
          for( i=0;i<((len)-(axlen+1));i++)
            if(item1.ahb_data[i] != item2.axi_data[i]) begin
              uvm_report_error("SCOREBOARD Data1 not the same" , "Master Monitor sent different data than Slave Monitor" );
             `uvm_info(get_type_name(), $sformatf("item1.ahb_adr[i] %h item2.axi_adr[i] %h item3.axi_adr[i] %h item1.ahb_data[i] %h item2.axi_data[i] %h i %d j %d axi_id %d",item1.start_addr, item2.axi_start_addr, item3.axi_start_addr,item1.ahb_data[i], item2.axi_data[i],i,j, item2.axi_id), UVM_LOW)
            end
          //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
            for( i=(len)-(axlen+1);i<len;i++)begin
              if(item1.ahb_data[i] != item3.axi_data[j]) begin
                uvm_report_error("SCOREBOARD Data2 not the same" , "Master Monitor sent different data than Slave Monitor" );
                `uvm_info(get_type_name(), $sformatf("item1.ahb_adr[i] %h item2.axi_adr[i] %h item3.axi_adr[i] %h item1.ahb_data[i] %h item2.axi_data[i] %h  i %d j %d  axi_id %d",item1.start_addr, item2.axi_start_addr, item3.axi_start_addr,item1.ahb_data[i], item3.axi_data[j], i,j,item3.axi_id), UVM_LOW)
              end
              //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
              j++;
            end
          if((item1.start_addr != item2.axi_start_addr) || ((item2.axi_start_addr + ((len-(axlen+1))*4)) != item3.axi_start_addr ))begin
            uvm_report_error("SCOREBOARD ADDRESS not the same" , "Master Monitor sent different addr than Slave Monitor" );
           `uvm_info(get_type_name(), $sformatf("item1.ahb_addr %h item2.axi_addr %h item3.axi_addr %h axi_id %d, axi_id %d",item1.start_addr,item2.axi_start_addr, item3.axi_start_addr,item2.axi_id,  item3.axi_id), UVM_LOW)
          end
        end
    end
   //second transfer is the smallest 
    else begin
       for( i=(axlen+1);i<len;i++)begin
         if(item1.ahb_data[i] != item3.axi_data[j]) begin
           uvm_report_error("SCOREBOARD Data1 not the same" , "Master Monitor sent different data than Slave Monitor" );
          `uvm_info(get_type_name(), $sformatf("item1.ahb_adr[i] %h item2.axi_adr[i] %h item3.axi_adr[i] %h item1.ahb_data[i] %h item2.axi_data[i] %h i%d j%d axi_id %d",item1.start_addr, item2.axi_start_addr, item3.axi_start_addr,item1.ahb_data[i], item3.axi_data[j],i,j, item3.axi_id), UVM_LOW)
         end
         j++;
       end
     //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
       for( i=0;i<(axlen+1);i++)begin
         if(item1.ahb_data[i] != item2.axi_data[i]) begin
           uvm_report_error("SCOREBOARD Data2 not the same" , "Master Monitor sent different data than Slave Monitor" );
          `uvm_info(get_type_name(), $sformatf("item1.ahb_adr[i] %h item2.axi_adr[i] %h item3.axi_adr[i] %h item1.ahb_data[i] %h item2.axi_data[i] %h axi_id %d",item1.start_addr, item2.axi_start_addr, item3.axi_start_addr,item1.ahb_data[i], item2.axi_data[i], item2.axi_id), UVM_LOW)
         end
       //else `uvm_info(get_type_name(), $sformatf("good "), UVM_LOW)
       //j++;
       end
        if((item1.start_addr != item2.axi_start_addr) || ((item2.axi_start_addr + ((axlen+1))*4 )!= item3.axi_start_addr) )begin
          uvm_report_error("SCOREBOARD ADDRESS not the same" , "Master Monitor sent different addr than Slave Monitor" );
         `uvm_info(get_type_name(), $sformatf("item1.ahb_addr %h item2.axi_addr %h item3.axi_addr %h axi_id %d, axi_id %d",item1.start_addr,item2.axi_start_addr, item3.axi_start_addr,item2.axi_id,  item3.axi_id), UVM_LOW)
        end
    end
    
  endfunction

 function void check_phase(uvm_phase phase);
    super.build_phase(phase);
    //sort items by appearance_time -> to check in right order
    write_slave_transfers.sort() with (item.appearance_time);
    read_slave_transfers.sort() with (item.appearance_time);
    //need this to check if all trasnfers are done
    actual_number_of_master_transfers  = master_transfers.size;
    actual_number_of_slave_transfers   = write_slave_transfers.size + read_slave_transfers.size;
    //first transfer needs to be the config tranimcsfer
    master_trans = master_transfers.pop_front();
    ->adress_space_cg_e;
    if(master_trans.start_addr == 'h100 && master_trans.ahb_op_type == AHB_WRITE)begin
      if(master_trans.ahb_wstrobe == 'hF ) ctrl_value = master_trans.ahb_data[0];
      else if( master_trans.ahb_wstrobe == 'h1 ) ctrl_value[7:0]   = master_trans.ahb_data[0][7:0] ;
      else if( master_trans.ahb_wstrobe == 'h2 ) ctrl_value[15:8]  = master_trans.ahb_data[0][15:8];
      else if( master_trans.ahb_wstrobe == 'h4 ) ctrl_value[23:16] = master_trans.ahb_data[0][23:16] ;
      else if( master_trans.ahb_wstrobe == 'h8 ) ctrl_value[31:24] = master_trans.ahb_data[0][31:24] ;
      else if( master_trans.ahb_wstrobe == 'h3 ) ctrl_value[15:0]  = master_trans.ahb_data[0][15:0] ;
      else if( master_trans.ahb_wstrobe == 'hC ) ctrl_value[31:16] = master_trans.ahb_data[0][31:16]; 
      
     expected_number_of_master_transfers++;
     //check oustanding bit configuration 
     if((ctrl_value & 32'h0000_0001) ==32'h0000_0001) begin
       if(outstanding != 1) uvm_report_error("AXI is not configured correctly" , "Outstanding not enabled" );
       else begin 
              if(ctrl_value[13:8] != 'd4 && ctrl_value[13:8] != 'd8 && ctrl_value[13:8] != 'd16 && ctrl_value[13:8] != 'd32)
                uvm_report_error("CTRL is not configured correctly" , "Number of outstanding must be 4, 8, 16 or 32" );
              if(ctrl_value[13:8] != number_of_write_transfers_outstanding)
          uvm_report_error("AXI is not configured correctly" , "Number of outstanding not configured correctly" );
         if(number_of_read_transfers_outstanding != 1)  uvm_report_error("AXI is not configured correctly" , "Number of reade outstanding not 0" );
       end 
     end  
     
     if((ctrl_value & 32'h0000_0001) ==32'h0000_0000) begin
       if(outstanding == 1) uvm_report_error("AXI is not configured correctly" , "Outstanding enabled" );
     end
       //check wrap bit configuration 
     if((ctrl_value & 32'h0000_0002) ==32'h0000_0002) begin //-wrap enabled
       //`uvm_info(get_type_name(), $sformatf("addr %h ",master_trans.start_addr), UVM_LOW)
       //`uvm_info(get_type_name(), $sformatf("addr %h ",ctrl_value), UVM_LOW)
      // check all trasnfers 
       while(master_transfers.size)begin
          master_trans = master_transfers.pop_front();
          expected_number_of_master_transfers++;
          //data address space -> check data 
          if(master_trans.start_addr <=32'hFFFF_FFFF && master_trans.start_addr >=32'h1000_0000) begin
            if(master_trans.ahb_op_type == AHB_WRITE)
              slave_trans = write_slave_transfers.pop_front();
            else 
              slave_trans = read_slave_transfers.pop_front();
              
            expected_number_of_slave_transfers++;
            //check for 4kb boundary crossed
            if((master_trans.ahb_burst_type==INCR4  &&(master_trans.start_addr[11:0]+  4*4>4096))||
               (master_trans.ahb_burst_type==INCR8  &&(master_trans.start_addr[11:0]+  8*4>4096))||
               (master_trans.ahb_burst_type==INCR16 &&(master_trans.start_addr[11:0]+ 16*4>4096)))
             //SPLIT
            begin
              //`uvm_info(get_type_name(), $sformatf("SPLIT"), UVM_LOW)
               expected_number_of_slave_transfers++;
               if(master_trans.ahb_op_type == AHB_WRITE)
                 check_data_integrity_4kb_crossed(master_trans,slave_trans, write_slave_transfers.pop_front());
               else 
                 check_data_integrity_4kb_crossed(master_trans,slave_trans, read_slave_transfers.pop_front());
            end
            else //no boundary crossed
              check_data_integrity_wrap(master_trans,slave_trans);
           
          end
          else begin//outside data space address
         
            if(master_trans.ahb_op_type == AHB_WRITE)begin //no write with this address must appear on wave
              if(write_slave_transfers.size != 0)
                foreach(write_slave_transfers[i]) begin
                  slave_transfers1  = (write_slave_transfers.find_first_index with ((item.axi_start_addr == master_trans.start_addr) && (item.axi_op_type == master_trans.ahb_op_type)&&(item.axi_size_type == master_trans.ahb_size_type) ));
                end
                 if(slave_transfers1 != {})  uvm_report_error("Address Space Error" , "Write performed outside the data space addr" );
                 //else $display("Passed");
            end
            else begin //if AHB_READ
              if(read_slave_transfers.size != 0)
                foreach(read_slave_transfers[i]) begin
                  slave_transfers1  = (read_slave_transfers.find_first_index with ((item.axi_start_addr == master_trans.start_addr) && (item.axi_op_type == master_trans.ahb_op_type)&&(item.axi_size_type == master_trans.ahb_size_type) ));
                end
              // if CTRL read -> ahb_data must be ctrl_value 
              if(master_trans.start_addr =='h100 && master_trans.ahb_op_type == AHB_READ) begin
                if(master_trans.ahb_data[0] != ctrl_value) 
                  uvm_report_error("CTRL Space Error" , "Read performed at 100 address, no ctrl_value" );
              //  `uvm_info(get_type_name(), $sformatf("master_trans.ahb_data[0] %d ctrl_value %d",master_trans.ahb_data[0],ctrl_value), UVM_LOW)
              end
              else begin//if outside addr space -> read data must be 0 && no error on AHB 
                if(slave_transfers1 != {})  uvm_report_error("Address Space Error" , "Read performed outside the data space addr" );
                //else $display("Passed");
                foreach(master_trans.ahb_data[i])begin
                  if(master_trans.ahb_data[i] != 'd0) uvm_report_error("Address Space Error" , "Read performed outside the data space addr, data not 0" );
                  if(master_trans.ahb_hresp != AHB_OKAY)uvm_report_error("Address Space Error" , "Read performed outside the data space addr, resp not OKAY" );
                end
              end
            end
          // $display("Passed");
          end
       end//while
     end//wrap enable
     //WRAP disable -> wrap must be transformed to INCR 
     else if((master_trans.ahb_data[0] & 32'h0000_0002) ==32'h0000_0000)  begin
       //`uvm_info(get_type_name(), $sformatf("no WRAP "), UVM_LOW)
       while(master_transfers.size)begin
         master_trans = master_transfers.pop_front();
       
         expected_number_of_master_transfers++;
         //if data space address
         if(master_trans.start_addr <=32'hFFFF_FFFF && master_trans.start_addr >=32'h1000_0000) begin
          //calc addr low
          case (master_trans.ahb_burst_type)
          //(INT(Start_Address/(Number_Bytes×Burst_Length)))×(Number_Bytes×Burst_Length)
            WRAP4:  addr_low= int'(master_trans.start_addr/(4 * 2**master_trans.ahb_size_type))*(4 * 2**master_trans.ahb_size_type);
            WRAP8:  addr_low= int'(master_trans.start_addr/(8 * 2**master_trans.ahb_size_type))*(8 * 2**master_trans.ahb_size_type);
            WRAP16: addr_low= int'(master_trans.start_addr/(16 *2**master_trans.ahb_size_type))*(16 *2**master_trans.ahb_size_type);
            default: addr_low= master_trans.start_addr;
          endcase
          if(master_trans.ahb_op_type == AHB_WRITE)
            slave_trans = write_slave_transfers.pop_front();
          else 
            slave_trans = read_slave_transfers.pop_front();
            
          expected_number_of_slave_transfers++;
          //check for 4KB boundary cross
          //`uvm_info(get_type_name(), $sformatf("addr %h ",slave_trans.axi_start_addr), UVM_LOW)
          if(((master_trans.ahb_burst_type==INCR4)  &&(master_trans.start_addr[11:0]+  4*4>4096))||
             ((master_trans.ahb_burst_type==INCR8)  &&(master_trans.start_addr[11:0]+  8*4>4096))||
             ((master_trans.ahb_burst_type==INCR16) &&(master_trans.start_addr[11:0]+ 16*4>4096))||
             //incr will have the start_addr == lowest addr from wrap -> must be checked 4k boundary
             ((master_trans.ahb_burst_type==WRAP4)  &&(addr_low+  4*4>4096))||
             ((master_trans.ahb_burst_type==WRAP8)  &&(addr_low+  8*4>4096))||
             ((master_trans.ahb_burst_type==WRAP16) &&(addr_low+ 16*4>4096)) )
             //SPLIT
            begin
             // `uvm_info(get_type_name(), $sformatf("SPLIT"), UVM_LOW)
              expected_number_of_slave_transfers++;
               if(master_trans.ahb_op_type == AHB_WRITE)
                check_data_integrity_4kb_crossed(master_trans,slave_trans, write_slave_transfers.pop_front());
               else check_data_integrity_4kb_crossed(master_trans,slave_trans, read_slave_transfers.pop_front());
            end
          else //no boundary crossed
            check_data_integrity_no_wrap(master_trans,slave_trans, addr_low);
         // `uvm_info(get_type_name(), $sformatf("done"), UVM_LOW) 
         
       //   `uvm_info(get_type_name(), $sformatf("addr_low %h ", slave_trans.axi_start_addr), UVM_LOW) 
        
         end
         else begin//outside the data address space
         
           if(master_trans.ahb_op_type == AHB_WRITE)begin//no write on AXI
             if(write_slave_transfers.size != 0)
               foreach(write_slave_transfers[i]) begin
                 slave_transfers1  = (write_slave_transfers.find_first_index with ((item.axi_start_addr == master_trans.start_addr) && (item.axi_op_type == master_trans.ahb_op_type)&&(item.axi_size_type == master_trans.ahb_size_type) ));
               end
           
             if(slave_transfers1 != {})  uvm_report_error("Address Space Error" , "Write performed outside the data space addr" );
          // else $display("Passed");
           end
           else begin//if ctrl value read
            if(master_trans.start_addr =='h100 && master_trans.ahb_op_type == AHB_READ) begin
              if( master_trans.ahb_data[0] != ctrl_value) 
                uvm_report_error("CTRL Space Error" , "Read performed at 100 address, no ctrl_value" );
            end
            else begin//if read outside data and ctrl space -> 0 data 0 error on AHB
              if(read_slave_transfers.size != 0)
                foreach(read_slave_transfers[i]) begin
                  slave_transfers1  = (read_slave_transfers.find_first_index with ((item.axi_start_addr == master_trans.start_addr) && (item.axi_op_type == master_trans.ahb_op_type)&&(item.axi_size_type == master_trans.ahb_size_type) ));
                end
                
                if(slave_transfers1 != {})  uvm_report_error("Address Space Error" , "Write performed outside the data space addr" );
            //  else $display("Passed");
                foreach(master_trans.ahb_data[i])begin
                  if(master_trans.ahb_data[i] != 'd0) uvm_report_error("Address Space Error" , "Read performed outside the data space addr, data not 0" );
                  if(master_trans.ahb_hresp != AHB_OKAY)uvm_report_error("Address Space Error" , "Read performed outside the data space addr, resp not OKAY" );
                end
          
            end  
          // $display("Passed");
         end
        
         end//else begin
       end//while
     end//no wrap
    end// if(master_trans.start_addr == 'h100 && master_trans.ahb_op_type == AHB_WRITE)begin
    else begin//if the first trasnfer is not at addr 'h100
      uvm_report_error("No Configuration ERROR" , "First you need to config the AHB2AXI Bridge! Write at addr 'h100" );
    end
    
    // check if expected nr of trasnfers == actual number of trasnfers received from monitors
    if(actual_number_of_master_transfers != expected_number_of_master_transfers)  begin
    `uvm_info(get_type_name(), $sformatf("actual_number_of_master_transfers %d expected_number_of_master_transfers &d",actual_number_of_master_transfers,expected_number_of_master_transfers), UVM_LOW) 
     uvm_report_error("SCOREBOARD NUMBER OF TRANSFERS not the same" , "Master Monitor didn't send expected number_of_master_transfers" );
    end
    
    if(actual_number_of_master_transfers != expected_number_of_master_transfers) begin
     `uvm_info(get_type_name(), $sformatf("actual_number_of_master_transfers %d expected_number_of_master_transfers &d",actual_number_of_master_transfers,expected_number_of_master_transfers), UVM_LOW) 
      uvm_report_error("SCOREBOARD NUMBER OF TRANSFERS not the same" , "Slave Monitor didn't send expected number_of_slave_transfers" );
    end
    
  endfunction: check_phase
  
endclass : ahb2axi_scoreboard
`endif
