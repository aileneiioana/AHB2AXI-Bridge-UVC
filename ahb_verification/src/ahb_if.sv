//------------------------------------
// File name   : ahb_if.sv
// Author      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AHB_IF_SV
`define AHB_IF_SV
localparam IDLE   = 'b00; // htrans
localparam BUSY   = 'b01; // htrans
localparam NONSEQ = 'b10; // htrans
localparam SEQ    = 'b11; // htrans

localparam SINGLE = 'b000; // hburst
localparam WRAP4  = 'b010; // hburst
localparam INCR4  = 'b011; // hburst
localparam WRAP8  = 'b100; // hburst
localparam INCR8  = 'b101; // hburst
localparam WRAP16 = 'b110; // hburst
localparam INCR16 = 'b111; // hburst

localparam BYTE   = 'b000; // hsize
localparam HWORD  = 'b001; // hsize
localparam WORD   = 'b010; // hsize

interface ahb_if #(AW=32,DW=32) (input hclk,input hreset_n);
 
  // Master wires
  wire            hsel;     //slave select
  wire            hwrite;   //write/read selector
  wire [1:0]      htrans;   //transfer type - IDLE, BUSY, SEQ, NONSEQ
  wire [2:0]      hburst;   //Single, Incr4, Wrap4, Incr8, Wrap8, Incr16, Wrap16
  wire [2:0]      hsize;    //Byte, Halfword, Word
  wire [AW-1:0]   haddr;    //registers address
  wire [DW-1:0]   hwdata;   //data from Master
  wire [3:0]      hwstrobe; //Write strobe. For bursts is all ones. For SINGLE can be between 1 and 15. If hsize is not Word, make sure the bits set to 1 are matching the selected Bytes.
 
  // Slave wires
  wire [DW-1:0]   hrdata;   //data from Slave
  wire            hreadyout;//Slave finished the transfer
  wire            hresp;    //Slave response 0-OKAY, 1-ERROR
 
  bit             has_checks;
 
  int i,j;
 
  //master clocking block
  clocking mst_cb @(posedge hclk);
    input   hrdata   ,
            hresp    ,
            hreadyout;
    output  haddr    ,
            hwdata   ,
            hsel     ,
            hwrite   ,
            htrans   ,
            hburst   ,
            hsize    ,
            hwstrobe ;
  endclocking:mst_cb  
 
  //slave clocking block
  clocking slv_cb @(posedge hclk);
   input    haddr    ,
            hwdata   ,
            hsel     ,
            hwrite   ,
            htrans   ,
            hburst   ,
            hsize    ,
            hwstrobe ;
    output  hrdata   ,
            hreadyout,
            hresp    ;
  endclocking:slv_cb
 
  //monitor clocking block - all signals are inputs
  clocking mon_cb @(posedge hclk);
     input  haddr    ,
            hwdata   ,
            hsel     ,
            hwrite   ,
            htrans   ,
            hburst   ,
            hsize    ,
            hwstrobe ,
            hrdata   ,
            hreadyout,
            hresp    ;
  endclocking:mon_cb


logic        stable_addr_and_data_flag = 0; // Flag for checking the haddr, hwdata. hrdata are stable when hreadyout is LOW
logic [31:0] address_incr_byte            ; // Variable for checking the address is computed correctly for INCR4, INCR8, INCR16 cases when hsize is BYTE
logic [31:0] address_incr_hword           ; // Variable for checking the address is computed correctly for INCR4, INCR8, INCR16 cases when hsize is HALFWORD
logic [31:0] address_incr_word            ; // Variable for checking the address is computed correctly for INCR4, INCR8, INCR16 cases when hsize is WORD
logic [31:0] address_wrap4_byte           ; // Variable for checking the address is computed correctly for WRAP4 case and hsize is BYTE
logic [31:0] address_wrap8_byte           ; // Variable for checking the address is computed correctly for WRAP8 case and hsize is BYTE
logic [31:0] address_wrap16_byte          ; // Variable for checking the address is computed correctly for WRAP16 case and hsize is BYTE
logic [31:0] address_wrap4_hword          ; // Variable for checking the address is computed correctly for WRAP4 case and hsize is HALFWORD
logic [31:0] address_wrap8_hword          ; // Variable for checking the address is computed correctly for WRAP8 case and hsize is HALFWORD
logic [31:0] address_wrap16_hword         ; // Variable for checking the address is computed correctly for WRAP16 case and hsize is HALFWORD
logic [31:0] address_wrap4_word           ; // Variable for checking the address is computed correctly for WRAP4 case and hsize is WORD
logic [31:0] address_wrap8_word           ; // Variable for checking the address is computed correctly for WRAP8 case and hsize is WORD
logic [31:0] address_wrap16_word          ; // Variable for checking the address is computed correctly for WRAP16 case and hsize is WORD

// Set the flag in 1 when hreadyout switch from 1->0 and in 0 when switch from 0->1
always @(posedge hclk)
if((htrans == NONSEQ | htrans == SEQ) & hreadyout == 'b0) stable_addr_and_data_flag <= 'b1; else
if((htrans == NONSEQ | htrans == SEQ) & hreadyout == 'b1) stable_addr_and_data_flag <= 'b0;

// Calculate the value of address for INCR4, INCR8, INCR16 cases when hsize is BYTE
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == BYTE & (hburst == INCR4 | hburst == INCR8 | hburst == INCR16)) address_incr_byte <= haddr;                     else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == BYTE & (hburst == INCR4 | hburst == INCR8 | hburst == INCR16)) address_incr_byte <= address_incr_byte + 3'b001;

// Calculate the value of address for INCR4, INCR8, INCR16 cases when hsize is HALFWORD
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == HWORD & (hburst == INCR4 | hburst == INCR8 | hburst == INCR16)) address_incr_hword  <= haddr;                       else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == HWORD & (hburst == INCR4 | hburst == INCR8 | hburst == INCR16)) address_incr_hword  <= address_incr_hword  + 3'b010;


// Calculate the value of address for INCR4, INCR8, INCR16 cases when hsize is WORD
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == WORD & (hburst == INCR4 | hburst == INCR8 | hburst == INCR16)) address_incr_word <= haddr;                     else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == WORD & (hburst == INCR4 | hburst == INCR8 | hburst == INCR16)) address_incr_word <= address_incr_word + 3'b100;

// Calculate the value of address for WRAP4 case when hsize is BYTE
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == BYTE & hburst == WRAP4) address_wrap4_byte <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == BYTE & hburst == WRAP4) address_wrap4_byte[1:0] <= address_wrap4_byte[1:0] + 1'b1;


// Calculate the value of address for WRAP4 case when hsize is HALFWORD
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == HWORD & hburst == WRAP4) address_wrap4_hword <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == HWORD & hburst == WRAP4) address_wrap4_hword[2:1] <= address_wrap4_hword[2:1] + 1'b1;


// Calculate the value of address for WRAP4 case when hsize is WORD
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == WORD & hburst == WRAP4) address_wrap4_word <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == WORD & hburst == WRAP4) address_wrap4_word[3:2] <= address_wrap4_word[3:2] + 1'b1;


// Calculate the value of address for WRAP8 case when hsize is BYTE
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == BYTE & hburst == WRAP8) address_wrap8_byte <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == BYTE & hburst == WRAP8) address_wrap8_byte[2:0] <= address_wrap8_byte[2:0] + 1'b1;


// Calculate the value of address for WRAP8 case when hsize is HALFWORD
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == HWORD & hburst == WRAP8) address_wrap8_hword <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == HWORD & hburst == WRAP8) address_wrap8_hword[3:1] <= address_wrap8_hword[3:1] + 1'b1;


// Calculate the value of address for WRAP8 case when hsize is WORD
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == WORD & hburst == WRAP8) address_wrap8_word <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == WORD & hburst == WRAP8) address_wrap8_word[4:2] <= address_wrap8_word[4:2] + 1'b1;


// Calculate the value of address for WRAP16 case when hsize is BYTE
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == BYTE & hburst == WRAP16) address_wrap16_byte <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == BYTE & hburst == WRAP16) address_wrap16_byte[3:0] <= address_wrap16_byte[3:0] + 1'b1;


// Calculate the value of address for WRAP16 case when hsize is HALFWORD
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == HWORD & hburst == WRAP16) address_wrap16_hword <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == HWORD & hburst == WRAP16) address_wrap16_hword[4:1] <= address_wrap16_hword[4:1] + 1'b1;


// Calculate the value of address for WRAP16 case when hsize is WORD
always @(posedge hclk)
if(htrans == NONSEQ & hreadyout == 'b1 & hsize == WORD & hburst == WRAP16) address_wrap16_word <= haddr; else
if(htrans == SEQ    & hreadyout == 'b1 & hsize == WORD & hburst == WRAP16) address_wrap16_word[5:2] <= address_wrap16_word[5:2] + 1'b1;



//******************************************************************** PROTOCOL ASSERTIONS ************************************************************//
// As long a transaction is processed, data should not be X or Z
ahb_data_unknown: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) hreset_n |-> (!$isunknown(hrdata && hresp && hreadyout && haddr && hwdata && hsel && hwrite && htrans && hburst && hsize && hwstrobe)));
 
// Output values under hreset_n
ahb_values_reset: assert property(@(posedge hclk) disable iff(hreset_n || !has_checks) !hreset_n |-> haddr == 0 && hwdata == 0 && hsel == 0 && hwrite == 0 && htrans == 0 && hburst == 0 && hsize == 0 && hwstrobe == 0);

// If the htrans transfer type changes to NONSEQ, the Manager must keep htrans constant, until hreadyout is HIGH
ahb_nonseq_transfer: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((htrans == NONSEQ && hreadyout == 'b0) |-> ##1 (htrans == NONSEQ)));

// If the htrans transfer type changes to SEQ, the Manager must keep htrans constant, until hreadyout is HIGH
ahb_seq_transfer: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((htrans == SEQ && hreadyout == 'b0) |-> ##1 (htrans == SEQ)));

// If the htrans transfer type changes to BUSY, the Manager can change the htrans to SEQ even if hreadyout is LOW or remain stable
ahb_busy_transfer: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((htrans == BUSY && hreadyout == 'b0) |-> ##1 (htrans == BUSY) || (htrans == SEQ) ));

// If hresp is HIGH, must to stay two cycles HIGH and hreadyout must be asserted HIGH on the 2nd cycle
ahb_hresp_error: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (hresp == 'b1) |-> ##1 ((hresp == 'b1) && (hreadyout == 'b1)) |-> ##1 hresp == 'b0 || hresp == 'b1 );

// The Manager is not permitted to perform a BUSY transfer immediately after a SINGLE burst. SINGLE bursts must be followed by an IDLE transfer or a NONSEQ transfer
ahb_single_transfer: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks || hreadyout == 'b0 || hresp == 'b1 ) ((htrans == NONSEQ) && (hburst == SINGLE)) |-> ##1 ((htrans == IDLE) || (htrans == NONSEQ)));

// If is a write operation hwstrobe can not be ‘b0
ahb_hwstrobe_wr_op: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks || hwrite == 'b0) hwrite == 'b1 |-> hwstrobe != 'b0);

// If hburst is SINGLE and hsize is BYTE,  make sure the bits set to 1 are matching the selected Bytes.
ahb_hwtrobe_single_byte: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((hburst == SINGLE) && (hsize == BYTE) && (htrans == NONSEQ)) |-> ((hwstrobe == 'b0001) || (hwstrobe == 'b0010) || (hwstrobe == 'b0100) || (hwstrobe == 'b1000)));

// If hburst is SINGLE and hsize is HWORD,  make sure the bits set to 1 are matching the selected Bytes.
ahb_hwtrobe_single_hword: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((hburst == SINGLE) && (hsize == HWORD)) |-> ((hwstrobe == 'b0011)  || (hwstrobe == 'b1100)));

// If hburst is SINGLE and hsize is WORD,  make sure the bits set to 1 are matching the selected Bytes.
ahb_hwtrobe_single_word: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((hburst == SINGLE) && (hsize == WORD)) |-> (hwstrobe == 'b1111));

// If hburst is different from SINGLE, hwtrobe must have all bits one.
ahb_hwtrobe_nsingle_word: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (hburst != SINGLE) |-> (hwstrobe == 'b1111));

//Check if during a waited transfer, the Master is permitted to change the transfer type from IDLE to NONSEQ
ahb_nonseq_after_idle: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((htrans == IDLE && hreadyout == 'b0) |-> ##1 (htrans == NONSEQ) || (htrans == IDLE)));

//Check when hready is LOW then haddr and hrdata and hwdata should remain in the same state until it hready goes HIGH
ahb_stable_addr_data: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) stable_addr_and_data_flag == 'b1 |-> (haddr == $past(haddr) && hwdata == $past(hwdata) && hrdata == $past(hrdata)));

// During a waited transfer for a fixed-length burst, the Master is permitted to change the transfer type from BUSY to SEQ
// When a Master uses the BUSY transfer type, the address and control signals must reflect the next transfer in the bursts
ahb_seq_after_busy_stable_signals: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((htrans == BUSY && hreadyout == 'b1) |-> ##1 (haddr == $past(haddr) && hsize == $past(hsize) && hburst == $past(hburst) && hwrite == $past(hwrite) && hwdata == $past(hwdata) && hrdata == $past(hrdata))));

// Check if the control information is identical to the previous transfer when is SEQ transfer type
ahb_seq_after_nonseq_stable_signals: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) ((htrans == NONSEQ && hreadyout == 'b1 && hburst != SINGLE) |-> ##1 (hsize == $past(hsize) && hburst == $past(hburst) && hwrite == $past(hwrite))));

// Check if address is computed correctly for INCR4, INCR8, INCR16 cases when hsize is BYTE
ahb_address_incr_byte: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == BYTE && (hburst == INCR4 || hburst == INCR8 || hburst == INCR16)) |-> (haddr == address_incr_byte + 3'b001));

// Check if address is computed correctly for INCR4, INCR8, INCR16 cases when hsize is HALDWORD
ahb_address_incr_hword: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == HWORD && (hburst == INCR4 || hburst == INCR8 || hburst == INCR16)) |-> (haddr == address_incr_hword + 3'b010));

// Check if address is computed correctly for INCR4, INCR8, INCR16 cases when hsize is WORD
ahb_address_incr_word: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == WORD && (hburst == INCR4 || hburst == INCR8 || hburst == INCR16)) |-> (haddr == address_incr_word + 3'b100));

// Check if address is computed correctly for WRAP4 case when hsize is BYTE
ahb_address_wrap4_byte: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == BYTE && (hburst == WRAP4)) |-> ((haddr[1:0] == address_wrap4_byte[1:0] + 1'b1) && (haddr[31:2] == address_wrap4_byte[31:2])));

// Check if address is computed correctly for WRAP4 case when hsize is HALFWORD
ahb_address_wrap4_hword: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == HWORD && (hburst == WRAP4)) |-> ((haddr[2:1] == address_wrap4_hword[2:1] + 1'b1) && (haddr[31:3] == address_wrap4_hword[31:3])));

// Check if address is computed correctly for WRAP4 case when hsize is WORD
ahb_address_wrap4_word: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == WORD && (hburst == WRAP4)) |-> ((haddr[3:2] == address_wrap4_word[3:2] + 1'b1) && (haddr[31:4] == address_wrap4_word[31:4])));

// Check if address is computed correctly for WRAP8 case when hsize is BYTE
ahb_address_wrap8_byte: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == BYTE && (hburst == WRAP8)) |-> ((haddr[2:0] == address_wrap8_byte[2:0] + 1'b1) && (haddr[31:3] == address_wrap8_byte[31:3])));

// Check if address is computed correctly for WRAP8 case when hsize is HALFWORD
ahb_address_wrap8_hword: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == HWORD && (hburst == WRAP8)) |-> ((haddr[3:1] == address_wrap8_hword[3:1] + 1'b1) && (haddr[31:4] == address_wrap8_hword[31:4])));

// Check if address is computed correctly for WRAP8 case when hsize is WORD
ahb_address_wrap8_word: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == WORD && (hburst == WRAP8)) |-> ((haddr[4:2] == address_wrap8_word[4:2] + 1'b1) && (haddr[31:5] == address_wrap8_word[31:5])));

// Check if address is computed correctly for WRAP16 case when hsize is BYTE
ahb_address_wrap16_byte: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == BYTE && (hburst == WRAP16)) |-> ((haddr[3:0] == address_wrap16_byte[3:0] + 1'b1)&&(haddr[31:4] == address_wrap16_byte[31:4])));

// Check if address is computed correctly for WRAP16 case when hsize is HALFWORD
ahb_address_wrap16_hword: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == HWORD && (hburst == WRAP16)) |-> ((haddr[4:1] == address_wrap16_hword[4:1] + 1'b1)&&(haddr[31:5] == address_wrap16_hword[31:5])));

// Check if address is computed correctly for WRAP16 case when hsize is WORD
ahb_address_wrap16_word: assert property(@(posedge hclk) disable iff(!hreset_n || !has_checks) (htrans == SEQ && hreadyout == 'b1 && hsize == WORD && (hburst == WRAP16)) |-> ((haddr[5:2] == address_wrap16_word[5:2] + 1'b1)&&(haddr[31:6] == address_wrap16_word[31:6])));

//Check if HBURST generates transfer correctly
hburst4_VALID: assume property (@ (posedge hclk) disable iff (!hreset_n)
   htrans == 2 && hreadyout && (hburst == INCR4 || hburst == WRAP4) |=>
   ((htrans[0] throughout (hreadyout && htrans[1])[->3]) |=>
   !htrans[0]) and ((hreadyout && htrans == 3)[=0:2] intersect !htrans[0][->1] |->
    hresp && hreadyout && !htrans)) else $display("hburst4 violation");
 
hburst8_VALID: assume property (@ (posedge hclk) disable iff (!hreset_n)
  htrans == 2 && hreadyout && (hburst == INCR8 || hburst == WRAP8)|=>
  ((htrans[0] throughout (hreadyout && htrans[1])[->7]) |=>
  !htrans[0]) and ((hreadyout && htrans == 3)[=0:6] intersect !htrans[0][->1] |->
  hresp && hreadyout && !htrans)) else $display("hburst8 violation");
 
hburst16_VALID: assume property (@ (posedge hclk) disable iff (!hreset_n)
  htrans == 2 && hreadyout && (hburst == INCR16 || hburst == WRAP16)|=>
  ((htrans[0] throughout (hreadyout && htrans[1])[->15]) |=>
  !htrans[0]) and ((hreadyout && htrans == 3)[=0:14] intersect !htrans[0][->1] |->
  hresp && hreadyout && !htrans)) else $display("hburst16 violation");

endinterface
`endif