//------------------------------------
// File name   : axi_trans.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_TRANS_SV
`define AXI_TRANS_SV

class axi_trans #(AW=32,DW=32) extends uvm_sequence_item;
 
  rand axi_trans_kind_t   axi_op_type               ; // AXI_READ or AXI_WRITE
  rand axi_size_kind_t    axi_size_type             ; // BYTE, HWORD, WORD
  rand axi_burst_kind_t   axi_burst_type            ; // FIXED, INCR, WRAP
  rand bit [3:0]          axi_length                ; // number of transfers - 1
  rand bit [DW-1:0]       axi_data [$]              ; // write/ read axi_data
  rand bit [3:0]          axi_wstrobe               ; // write strobe, just for SINGLE transfer
  rand axi_trans_resp_t   axi_resp                  ; // type of response: AXI_OKAY, AXI_EXOKAY, AXI_SLVERR, AXI_DECERR
  rand bit [31:0]         axi_start_addr            ; // AXI ADDRESS has to be alligned
  rand bit [3:0]          axi_id                    ; // same for aw & b and for ar & r
 
  
  rand axi_axlock_kind_t  axi_lock                  ; // NORMAL_ACCESS, EXCLUSIVE_ACCESS,  LOCKED_ACCESS, RESERVED
  rand axi_axcache_kind_t axi_cache                 ; // Device_Nonbufferable, Device_Bufferable, Normal_NonCacheable_NonBufferable, Normal_NonCacheable_Bufferable, WriteThrough_NoAllocate, WriteThrough_ReadAllocate, WriteThrough_WriteAllocate, WriteThroughRead_WriteAllocate,WriteBac_NoAllocate, WriteBack_ReadAllocate, WriteBack_WriteAllocate, WriteBackRead_WriteAllocate
  rand axi_axprot_kind_t  axi_prot                  ; // UNPRIVILEGED, PRIVILEGED, SECURE, NONSECURE, DATAACCESS, INSTRUCTIONACCESS

  
  rand int unsigned      delay_between_addr          ; // delay between awvalid & awready to awvalid
  rand axi_delay_kind_t  delay_between_addr_kind     ; // ZERO, SHORT, MEDIUM, LARGE, MAX
  
  rand int unsigned      delay_between_data          ; // delay between wvalid & wready&wlast to wvalid
  rand axi_delay_kind_t  delay_between_data_kind     ; // ZERO, SHORT, MEDIUM, LARGE, MAX
  
  rand int unsigned      delay_between_addr_data     ; // delay between awvalid & awready to wvalid
  rand axi_delay_kind_t  delay_between_addr_data_kind; // ZERO, SHORT, MEDIUM, LARGE, MAX
  
  rand int unsigned      delay_between_addr_resp     ; // delay between wlast &&  bvalid
  rand axi_delay_kind_t  delay_between_addr_resp_kind; // ZERO, SHORT, MEDIUM, LARGE, MAX

  
  rand axi_ready_kind_t  rready_pattern;
  rand axi_ready_kind_t  bready_pattern; 
  
  rand bit four_kb_boundary_enable ;
  
  int unsigned      appearance_time;
  
  `uvm_object_utils_begin(axi_trans)
    `uvm_field_enum(axi_trans_kind_t, axi_op_type, UVM_ALL_ON)
    `uvm_field_enum(axi_size_kind_t, axi_size_type, UVM_ALL_ON)
    `uvm_field_enum(axi_burst_kind_t, axi_burst_type, UVM_ALL_ON)
    `uvm_field_int(axi_length, UVM_ALL_ON)
    `uvm_field_int(axi_start_addr, UVM_ALL_ON)
    `uvm_field_queue_int(axi_data, UVM_ALL_ON) 
    `uvm_field_enum(axi_trans_resp_t, axi_resp, UVM_ALL_ON) 
    `uvm_field_int(axi_wstrobe, UVM_ALL_ON)
    `uvm_field_int(axi_id, UVM_ALL_ON)
    `uvm_field_int(delay_between_addr, UVM_ALL_ON)
    `uvm_field_enum(axi_delay_kind_t, delay_between_addr_kind, UVM_ALL_ON)
    `uvm_field_enum(axi_ready_kind_t, rready_pattern, UVM_ALL_ON)
    `uvm_field_enum(axi_ready_kind_t, bready_pattern, UVM_ALL_ON)
    `uvm_field_int(delay_between_data, UVM_ALL_ON)
    `uvm_field_enum(axi_delay_kind_t, delay_between_data_kind, UVM_ALL_ON)
    `uvm_field_int(delay_between_addr_data, UVM_ALL_ON)
    `uvm_field_enum(axi_delay_kind_t, delay_between_addr_data_kind, UVM_ALL_ON)
    `uvm_field_int(delay_between_addr_resp, UVM_ALL_ON)
    `uvm_field_enum(axi_delay_kind_t, delay_between_addr_resp_kind, UVM_ALL_ON)
    `uvm_field_enum(axi_axlock_kind_t, axi_lock, UVM_ALL_ON)
    `uvm_field_enum(axi_axcache_kind_t, axi_cache, UVM_ALL_ON)
    `uvm_field_enum(axi_axprot_kind_t, axi_prot, UVM_ALL_ON)
    `uvm_field_int(four_kb_boundary_enable, UVM_ALL_ON)
    `uvm_field_int(appearance_time, UVM_ALL_ON)
  `uvm_object_utils_end
  
    constraint address_4k_boundary_c {
                            if(four_kb_boundary_enable) 
                              //if ((axi_start_addr + (2**axi_size_type * (axi_length+1))) > 4096)
                                axi_start_addr inside{[0:(4096 -(2**axi_size_type * (axi_length+1)))]} ;  //0...4kb
                            }
  
    constraint wstrobe_c { if(axi_length==0){
                             if(axi_size_type == WORD ) axi_wstrobe == 15;
                             if(axi_size_type == HWORD) axi_wstrobe inside {3, 12};
                             if(axi_size_type == BYTE ) axi_wstrobe inside {1, 2, 4, 8};
                             }
                             else axi_wstrobe == 15;
                        }

  
    constraint delay_between_addr_order_c { solve delay_between_addr_kind before delay_between_addr; }
   
    constraint delay_between_addr_c { 
                             (delay_between_addr_kind == ZERO  ) -> delay_between_addr == 0            ;
                             (delay_between_addr_kind == SHORT ) -> delay_between_addr inside{[1:5]}   ;
                             (delay_between_addr_kind == MEDIUM) -> delay_between_addr inside {[6:10]} ;
                             (delay_between_addr_kind == LARGE ) -> delay_between_addr inside {[11:19]};
                             (delay_between_addr_kind == MAX   ) -> delay_between_addr >= 20           ;
                                                                 delay_between_addr >= 0            ;
                                                                 delay_between_addr <= 100          ;
                           }


    constraint delay_between_data_order_c { solve delay_between_data_kind before delay_between_data; }
   
    constraint delay_between_data_c { 
                             (delay_between_data_kind == ZERO  ) -> delay_between_data == 0            ;
                             (delay_between_data_kind == SHORT ) -> delay_between_data inside{[1:5]}   ;
                             (delay_between_data_kind == MEDIUM) -> delay_between_data inside {[6:10]} ;
                             (delay_between_data_kind == LARGE ) -> delay_between_data inside {[11:19]};
                             (delay_between_data_kind == MAX   ) -> delay_between_data >= 20           ;
                                                                 delay_between_data >= 0            ;
                                                                 delay_between_data <= 100          ;
                           }
                           
                           
    constraint delay_between_addr_data_order_c { solve delay_between_addr_data_kind before delay_between_addr_data; }
   
    constraint delay_between_addr_data_c { 
                             (delay_between_addr_data_kind == ZERO  ) -> delay_between_addr_data == 0            ;
                             (delay_between_addr_data_kind == SHORT ) -> delay_between_addr_data inside{[1:5]}   ;
                             (delay_between_addr_data_kind == MEDIUM) -> delay_between_addr_data inside {[6:10]} ;
                             (delay_between_addr_data_kind == LARGE ) -> delay_between_addr_data inside {[11:19]};
                             (delay_between_addr_data_kind == MAX   ) -> delay_between_addr_data >= 20           ;
                                                                 delay_between_addr_data >= 0            ;
                                                                 delay_between_addr_data <= 100          ;
                           }
                       
    
    constraint delay_between_addr_resp_order_c { solve delay_between_addr_resp_kind before delay_between_addr_resp; }
   
    constraint delay_between_addr_resp_c { 
                             (delay_between_addr_resp_kind == ZERO  ) -> delay_between_addr_resp == 0            ;
                             (delay_between_addr_resp_kind == SHORT ) -> delay_between_addr_resp inside{[1:5]}   ;
                             (delay_between_addr_resp_kind == MEDIUM) -> delay_between_addr_resp inside {[6:10]} ;
                             (delay_between_addr_resp_kind == LARGE ) -> delay_between_addr_resp inside {[11:19]};
                             (delay_between_addr_resp_kind == MAX   ) -> delay_between_addr_resp >= 20           ;
                                                                 delay_between_addr_resp >= 0            ;
                                                                 delay_between_addr_resp <= 100          ;
                           }
                       
    
    
    constraint axi_data_size {
        solve axi_length before axi_data;
        solve axi_size_type before axi_data;
        axi_data.size() == axi_length+1;
    }
    


    constraint axi_length_val {
        /*  solve order constraints  */
        solve axi_burst_type before axi_length;

        /*  rand variable constraints  */
        if(axi_burst_type == FIXED)
            axi_length inside { 0};
        else if(axi_burst_type == WRAP)
            axi_length inside { 1, 3, 7, 15 };
    }
    
    
    constraint axi_start_addr_val {
        solve axi_burst_type before axi_start_addr;
        solve axi_size_type before axi_start_addr;
        axi_start_addr == int'(axi_start_addr/2**axi_size_type) * 2**axi_size_type;
    }

 
  function new (string name = "axi_trans");
    super.new(name);
  endfunction


endclass:axi_trans

`endif