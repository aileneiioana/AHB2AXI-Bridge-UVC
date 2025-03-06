//------------------------------------
// File name   : ahb_trans.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_TRANS_SV
`define AHB_TRANS_SV
 
class ahb_trans #(AW=32,DW=32) extends uvm_sequence_item;
 
  // Master relevant
  rand ahb_trans_kind_t  ahb_op_type          ; // AHB_READ or AHB_WRITE
  rand ahb_hsize_kind_t  ahb_size_type        ; // BYTE, HWORD, WORD
  rand ahb_hburst_kind_t ahb_burst_type       ; // SINGLE, INCR4, WRAP4, INCR8, WRAP8, INCR16, WRAP16 
  rand bit [DW-1:0]      ahb_data [$]         ; // write/ read data
  
  rand int unsigned      ahb_trans_delay      ; // delay between transactions
  rand ahb_delay_kind_t  ahb_trans_delay_kind ; // type of delay between transactions: ZERO SHORT MEDIUM LARGE MAX
  rand bit [3:0]         ahb_wstrobe          ; // write strobe, just for SINGLE transfer
 
  // Slave relevant
  rand ahb_trans_resp_t  ahb_hresp            ; // type of response: AHB_OKAY, AHB_ERROR
  rand int               ahb_ready_delay      ; // hready delay
  rand ahb_hready_kind_t ahb_hready_kind      ; // hready delay kind: ZERO, SHORT, MEDIUM, LONG
 
  rand int               busy_cycles          ; // how many BUSY cycles are in a transfer
 
  rand int               idle_cycles_start    ; // how many IDLE cycles in front of the transfer
  rand int               idle_cycles_end      ; // how many IDLE cycles at the end of the transfer

 
  rand bit [31:0]        start_addr           ; // if we want a specific start address for WRAP
  
  rand bit               error_enable         ;
 
  rand axi_burst_kind_t   axi_burst_type            ; // FIXED, INCR, WRAP
  rand bit [1:0]          addr_mode;
 
  `uvm_object_utils_begin(ahb_trans)
    `uvm_field_enum(ahb_trans_kind_t, ahb_op_type, UVM_ALL_ON)
    `uvm_field_enum(ahb_hsize_kind_t, ahb_size_type, UVM_ALL_ON)
    `uvm_field_enum(ahb_hburst_kind_t, ahb_burst_type, UVM_ALL_ON)
    `uvm_field_int(start_addr, UVM_ALL_ON)
    `uvm_field_queue_int(ahb_data, UVM_ALL_ON) 
    `uvm_field_enum(ahb_trans_resp_t, ahb_hresp, UVM_ALL_ON) 
    `uvm_field_int(ahb_wstrobe, UVM_ALL_ON)
    `uvm_field_int(ahb_trans_delay, UVM_ALL_ON)
    `uvm_field_enum(ahb_delay_kind_t, ahb_trans_delay_kind, UVM_ALL_ON)
    `uvm_field_int(ahb_ready_delay, UVM_ALL_ON)
    `uvm_field_int(busy_cycles, UVM_ALL_ON) 
    `uvm_field_enum(ahb_hready_kind_t, ahb_hready_kind, UVM_ALL_ON)
    `uvm_field_int(error_enable, UVM_ALL_ON)
    `uvm_field_enum(axi_burst_kind_t, axi_burst_type, UVM_ALL_ON)
    `uvm_field_int(addr_mode, UVM_ALL_ON)
  `uvm_object_utils_end

 
  constraint hwstrobe_c { 
                          if(ahb_burst_type != SINGLE ) 
                             ahb_wstrobe == 15;
                          else
                          {
                             if(ahb_size_type == WORD ) ahb_wstrobe == 15;
                             if(ahb_size_type == HWORD) ahb_wstrobe inside {3, 12};
                             if(ahb_size_type == BYTE ) ahb_wstrobe inside {1, 2, 4, 8};
                          }
                        }

  constraint trans_delay_order_c { solve ahb_trans_delay_kind before ahb_trans_delay; }
   
  constraint trans_delay_c { 
                             (ahb_trans_delay_kind == ZERO  ) -> ahb_trans_delay == 0            ;
                             (ahb_trans_delay_kind == SHORT ) -> ahb_trans_delay inside{[1:5]}   ;
                             (ahb_trans_delay_kind == MEDIUM) -> ahb_trans_delay inside {[6:10]} ;
                             (ahb_trans_delay_kind == LARGE ) -> ahb_trans_delay inside {[11:19]};
                             (ahb_trans_delay_kind == MAX   ) -> ahb_trans_delay >= 20           ;
                                                                 ahb_trans_delay >= 0            ;
                                                                 ahb_trans_delay <= 100          ;
                           }

  constraint addr_size {                                                          ahb_data.size  > 0 ;
                         if(ahb_burst_type == SINGLE                            ) ahb_data.size == 1 ;
                         if(ahb_burst_type == INCR4  || ahb_burst_type == WRAP4 ) ahb_data.size == 4 ;
                         if(ahb_burst_type == INCR8  || ahb_burst_type == WRAP8 ) ahb_data.size == 8 ;
                         if(ahb_burst_type == INCR16 || ahb_burst_type == WRAP16) ahb_data.size == 16;
                       }
      
 

 //constraint busy_cycle_count_c {  if(ahb_burst_type != SINGLE) busy_cycles inside {[1:20]}; else busy_cycles==0;}
   constraint busy_cycle_count_c {  busy_cycles==0;}
  constraint idle_cycle_count_start_c { if(ahb_trans_delay) idle_cycles_start inside {[0:5]}; else idle_cycles_start==0;}
  //constraint idle_cycle_count_start_c { idle_cycles_start==0;}
 
  constraint idle_cycle_count_end_c {  if(ahb_trans_delay) idle_cycles_end inside {[0:5]}; else idle_cycles_end==0; }
 // constraint idle_cycle_count_end_c { idle_cycles_end==0; }
  
      constraint ahb_start_addr_val {
        solve ahb_burst_type before start_addr;
        solve ahb_size_type before start_addr;
        start_addr == int'(start_addr/2**ahb_size_type) * 2**ahb_size_type;
    }
    constraint ahb_burst_size_c {
        solve ahb_burst_type before ahb_size_type;
        if(ahb_burst_type) ahb_size_type == WORD ;
    }
  
   constraint start_c {  
    if(addr_mode == 1) start_addr inside {[32'h1000_0000:32'hFFFF_FFFF]};
    else if (addr_mode==0) start_addr == 'h100;
    else  start_addr inside {[32'h0000_0000:32'h0000_FFFF]};
   }
   
   constraint start_delay {
    if (addr_mode==0) ahb_trans_delay > 0;
   }
   
   function new (string name = "ahb_trans");
    super.new(name);
   endfunction

endclass:ahb_trans

`endif