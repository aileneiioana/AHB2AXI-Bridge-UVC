//------------------------------------
// File name   : ahb_types.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_TYPES_SV
`define AHB_TYPES_SV

typedef enum bit {AHB_MASTER, AHB_SLAVE           } ahb_agent_kind_t;
typedef enum bit {AHB_WRITE = 1'b1, AHB_READ= 1'b0} ahb_trans_kind_t;
typedef enum bit {AHB_OKAY= 1'b0, AHB_ERROR= 1'b1 } ahb_trans_resp_t;
typedef enum     {ZERO, SHORT, MEDIUM, LARGE, MAX } ahb_delay_kind_t;  // delay between transactions
typedef enum     {ALWAYS_1, TOGGLE_1, RANDOM      } ahb_hready_kind_t; // delay for hready 

typedef enum bit [2:0] {
                        SINGLE  = 3'b000  ,  // single burst
                        //INCR    = 3'b001,  // incrementing burst of undefinded length
                        WRAP4   = 3'b010  ,  // 4-beat wrapping burst
                        INCR4   = 3'b011  ,  // 4-beat incrementing burst
                        WRAP8   = 3'b100  ,  // 8-beat wrapping burst
                        INCR8   = 3'b101  ,  // 8-beat incrementing burst
                        WRAP16  = 3'b110  ,  // 16-beat wrapping burst
                        INCR16  = 3'b111     // 16-beat incrementing burst 
                        } ahb_hburst_kind_t;
                        
typedef enum bit [2:0] {
                        BYTE   = 3'b000  ,   // byte
                        HWORD  = 3'b001  ,   // half word or 16-bits
                        WORD   = 3'b010      // word or 32-bits 
                       } ahb_hsize_kind_t; 
                       
typedef enum bit [1:0] {
                        IDLE   = 2'b00    ,  // indicates that no data transfer is required
                        BUSY   = 2'b01    ,  // indicates that the Manager is continuing with a burst, but the next transfer cannot take immediately
                        NONSEQ = 2'b10    ,  // indictaes a single transfer or the first transfer of a burst
                        SEQ    = 2'b11       // the remaining transfers in a burst are SEQ
                       } ahb_htrans_kind_t;
                       
typedef enum bit  [1:0] {FIXED, INCR, WRAP} axi_burst_kind_t;  
                       

`endif
