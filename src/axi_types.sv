//------------------------------------
// File name   : axi_types.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXI_TYPES_SV
`define AXI_TYPES_SV

typedef enum bit  {AXI_MASTER, AXI_SLAVE} axi_agent_kind_t;

typedef enum bit  {AXI_READ, AXI_WRITE} axi_trans_kind_t;

typedef enum bit  [1:0] {AXI_OKAY, AXI_EXOKAY ,AXI_SLVERR , AXI_DECERR} axi_trans_resp_t;  

typedef enum bit  [2:0] {ZERO, SHORT, MEDIUM, LARGE, MAX} axi_delay_kind_t; 

typedef enum bit  [1:0] {ALWAYS_1, TOGGLE_1, RANDOM} axi_ready_kind_t; 

typedef enum bit  [1:0] {FIXED, INCR, WRAP} axi_burst_kind_t;     

typedef enum bit  [1:0] {BYTE, HWORD,  WORD} axi_size_kind_t; 

typedef enum bit  [1:0] {NORMAL_ACCESS, EXCLUSIVE_ACCESS,  LOCKED_ACCESS, RESERVED} axi_axlock_kind_t; 

typedef enum bit  [3:0] {
                         Device_Nonbufferable, Device_Bufferable, 
                         Normal_NonCacheable_NonBufferable, Normal_NonCacheable_Bufferable,
                         WriteThrough_NoAllocate, WriteThrough_ReadAllocate, 
                         WriteThrough_WriteAllocate, WriteThroughRead_WriteAllocate,
                         WriteBack_NoAllocate, WriteBack_ReadAllocate, 
                         WriteBack_WriteAllocate, WriteBackRead_WriteAllocate
                         } axi_axcache_kind_t;
                         
typedef enum bit [2:0] {UNPRIVILEGED, PRIVILEGED, SECURE, NONSECURE, DATAACCESS, INSTRUCTIONACCESS}  axi_axprot_kind_t;


`endif
