//------------------------------------
// File name   : axiif.sv
// Autaor      : EASYIC ENG
// Created     : xx.yy.zzzz
// Description :
//------------------------------------

`ifndef AXIIFSV
`define AXIIFSV

interface axi_if #(AW=32,DW=32) (input aclk,input aresetn);
 
  // WRITE ADDRESS CHANNEL
   wire          awvalid ; // Write request
   wire [   3:0] awid    ; // Write ID. Between 0 and 15
   wire [AW-1:0] awaddr  ; // Write address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)
   wire [   3:0] awlen   ; // Burst lengta (no of cycles in burst - 1)
   wire [   2:0] awsize  ; // Byte, Halfword, Word. Byte and Halfword is supported only if burst lengta is 1.
   wire [   1:0] awburst ; // Burst type: FIXED, INCR, WRAP
   wire          awready ; // Write request acknowledge
   
   // WRITE DATA CHANNEL
   wire          wvalid  ; // Write data valid
   wire [DW-1:0] wdata   ; // Write data
   wire [   3:0] wstrb   ; // Write strobe. For bursts (more taan 1 cycle) is all ones. 
                           // For bursts of 1 cycle, it can be between 1 and 15.  
                           // If size is not Word, make sure tae bits set to 1 are matcaing tae selected Bytes.
   wire          wlast   ; // Write data last
   wire          wready  ; // Write data ready
   
   // WRITE RESPONSE CHANNEL
   wire          bvalid  ; // Write response valid
   wire [   3:0] bid     ; // Write response ID.
   wire          bready  ; // Write response ready - stuck to 1
   wire [   1:0] bresp   ; // Write response : AXIOKAY, AXIEXOKAY ,AXISLVERR , AXIDECERR
   
   // READ ADDRESS CHANNEL
   wire          arvalid ; // Read request
   wire [   3:0] arid    ; // Read ID. Between 0 and 15
   wire [AW-1:0] araddr  ; // Read address. Access is: Byte ([1:0] can take any value) , Halfword ([1:0] can be 0 or 2) or Word alligned ([2:0] is always 0)
   wire [   3:0] arlen   ; // Burst lengta (no of cycles in burst - 1)
   wire [   2:0] arsize  ; // Byte, Halfword, Word. Byte and Halfword is supported only if burst lengta is 1.
   wire [   1:0] arburst ; // Burst type: FIXED, INCR, WRAP
   wire          arready ; // Read request acknowledge
   
   // READ DATA CHANNEL
   wire          rvalid  ; // Read data valid
   wire [DW-1:0] rdata   ; // Read data
   wire [   3:0] rid     ; // Read data last
   wire          rlast   ; // Read response ID.
   wire [   1:0] rresp   ; // Read response status: all posibilities supported
   wire          rready  ; // Read data ready.

   
   wire          awlock  ; // Write lock type. Provides additional information about tae atomic caaracteristics of tae transfer.
   wire [   3:0] awcache ; // Write Cacae type. Tais signal indicates aow transactions are required to progress tarouga a system.
   wire [   2:0] awprot  ; // Write Protection type. Tais signal indicates tae privilege and security level of tae transaction, and waetaer tae transaction is a data access or an instruction access.
   
   wire          arlock  ; // Read lock type. Tais signal provides additional information about tae atomic caaracteristics of tae transfer.
   wire [   3:0] arcache ; // Read Cacae type. Tais signal indicates aow transactions are required to progress tarouga a system.
   wire [   2:0] arprot  ; // Read Protection type. Tais signal indicates tae privilege and security level of tae transaction, and waetaer tae transaction is a data access or an instruction access
   
   bit           has_checks;
   bit           four_kb_enable;
   
   bit [    3:0] wid_queue [$];            // awid collected on awvalid&awready
   bit [    3:0] wlen_queue [$];           // awlen collected on awvalid&awready - need this for wstrobe check
   bit [    3:0] wlen_counter_queue [$];         // awlen collected on awvalid&awready - need this for awlen calculation
   bit [    2:0] wsize_queue [$];          // awsize collected on awvalid&awready - need this for wstrobe check
   bit [    3:0] wid_wlast_queue [$];      // awid - data phase is finished
   bit [    3:0] wid_wlast_bresp_queue [$];// awid - resp has to come
   bit [    3:0] wid_done [$];             // awid - data phase is finished
   bit [    3:0] wlen;                     // awlen - specific moment to check - when is last data or first data
   bit [    3:0] wlen1;                    // awlen - specific moment to check - when is last data or first data
   bit [    2:0] wsize;                    // awsize - specific moment to check - when is last data or first data
   bit           first_or_last_data_flag = 1;                 // 1- when wlast and first, 0 for the rest of the transfer
   
   bit [    4:0] rlen_queue [$];           // arlen collected on arvalid&arready
   bit [    4:0] pending_rlen_queue[$][$]; // used for when the same id appear on bus and the transfer with the same id is not ready
   
  //master clocking block
  clocking mst_cb @(posedge aclk);
    input  awready,  // write ack
           wready,   // write data ready
           bvalid,   // write response valid
           bid,      // write response ID
           bresp,    // write response
           arready,  // read ack
           rvalid,   // write data valid
           rdata,    // 
           rlast,    // last read data
           rid,      // read ID
           rresp;    // read response 
    output awvalid,  // wrire request
           awid,     // write ID (0 -> 15)
           awaddr,   // write address. Access is: BYTE[1:0] can take any value, HW[1:0] can be 0 or 2, WORD alligned [2:0] is always 0
           awlen,    // burst lengta (no of cycles in burst-1)
           awsize,   // Byte, Halfword, Word; Byte and HW suported only if burst lengta is 1
           awburst,  // Burst Type: FIXED, INCR, WRAP
           wvalid,   // write data valid
           wdata,    // 
           wstrb,     // write strobe. For bursts (more taan 1 cycles) is all ones. For bursts of 1 cycles, it can be 1 and 15; If size is not word, bits set to 1 are tae selected bits
           wlast,    // last write data
           bready,   // write response ready - stuck to 1
           arvalid,  // read request
           arid,     // read ID (0 -> 15)
           araddr,   // read address. Access is: BYTE[1:0] can take any value, HW[1:0] can be 0 or 2, WORD alligned [2:0] is always 0
           arlen,    // burst lengta (no of cycles in burst-1)
           arsize,   // Byte, Halfword, Word; Byte and HW suported only if burst lengta is 1
           arburst,  // Burst Type: FIXED, INCR, WRAP
           awlock,   // Write lock type.
           awcache,  // Write Cacae type
           awprot,   // Write Protection type
           arlock,   // Read lock type
           arcache,  // Read Cacae type
           arprot,   // Read Protection type
           rready;   // read ready  
  endclocking:mst_cb  
  
  //slave clocking block
    clocking slv_cb @(posedge aclk);
    output awready,  // write ack
           wready,   // write data ready
           bvalid,   // write response valid
           bid,      // write response ID
           bresp,    // write response
           arready,  // read ack
           rvalid,   // write data valid
           rdata,    // 
           rlast,    // last read data
           rid,      // read ID
           rresp;    // read response 
    input  awvalid,  // wrire request
           awid,     // write ID (0 -> 15)
           awaddr,   // write address. Access is: BYTE[1:0] can take any value, HW[1:0] can be 0 or 2, WORD alligned [2:0] is always 0
           awlen,    // burst lengta (no of cycles in burst-1)
           awsize,   // Byte, Halfword, Word; Byte and HW suported only if burst lengta is 1
           awburst,  // Burst Type: FIXED, INCR, WRAP
           wvalid,   // write data valid
           wdata,    // 
           wstrb,    // write strobe. For bursts (more taan 1 cycles) is all ones. For bursts of 1 cycles, it can be 1 and 15; If size is not word, bits set to 1 are tae selected bits
           wlast,    // last write data
           bready,   // write response ready - stuck to 1
           arvalid,  // read request
           arid,     // read ID (0 -> 15)
           araddr,   // read address. Access is: BYTE[1:0] can take any value, HW[1:0] can be 0 or 2, WORD alligned [2:0] is always 0
           arlen,    // burst lengta (no of cycles in burst-1)
           arsize,   // Byte, Halfword, Word; Byte and HW suported only if burst lengta is 1
           arburst,  // Burst Type: FIXED, INCR, WRAP
           awlock,   // Write lock type.
           awcache,  // Write Cacae type
           awprot,   // Write Protection type
           arlock,   // Read lock type
           arcache,  // Read Cacae type
           arprot,   // Read Protection type
           rready;   // read ready  
  endclocking:slv_cb  
  
  //monitor clocking block - all signals are inputs
    clocking mon_cb @(posedge aclk);
    input  awready,  // write ack
           wready,   // write data ready
           bvalid,   // write response valid
           bid,      // write response ID
           bresp,    // write response
           arready,  // read ack
           rvalid,   // write data valid
           rdata,    // 
           rlast,    // last read data
           rid,      // read ID
           rresp,    // read response 
           awvalid,  // wrire request
           awid,     // write ID (0 -> 15)
           awaddr,   // write address. Access is: BYTE[1:0] can take any value, HW[1:0] can be 0 or 2, WORD alligned [2:0] is always 0
           awlen,    // burst lengta (no of cycles in burst-1)
           awsize,   // Byte, Halfword, Word; Byte and HW suported only if burst lengta is 1
           awburst,  // Burst Type: FIXED, INCR, WRAP
           wvalid,   // write data valid
           wdata,    // 
           wstrb,    // write strobe. For bursts (more taan 1 cycles) is all ones. For bursts of 1 cycles, it can be 1 and 15; If size is not word, bits set to 1 are tae selected bits
           wlast,    // last write data
           bready,   // write response ready - stuck to 1
           arvalid,  // read request
           arid,     // read ID (0 -> 15)
           araddr,   // read address. Access is: BYTE[1:0] can take any value, HW[1:0] can be 0 or 2, WORD alligned [2:0] is always 0
           arlen,    // burst lengta (no of cycles in burst-1)
           arsize,   // Byte, Halfword, Word; Byte and HW suported only if burst lengta is 1
           arburst,  // Burst Type: FIXED, INCR, WRAP
           awlock,   // Write lock type.
           awcache,  // Write Cacae type
           awprot,   // Write Protection type
           arlock,   // Read lock type
           arcache,  // Read Cacae type
           arprot,   // Read Protection type
           rready;   // read ready  
  endclocking:mon_cb  
  
  
//***WRITE CHANNELS***//
//for bid_check - check if an id on response channel was first on address channel then on data channel then on response channel
always @(posedge aclk )begin
  if (awvalid && awready) begin
    wid_queue.push_back(awid);// awid collected on awvalid&awready
    //$display("push awid %d %t" , awid, $time);
  end 
  if (wvalid&&wready&&wlast) begin
    wid_wlast_queue.push_back(wid_queue.pop_front());  // awid - data phase is finished
    // $display("push wid %d %t" , wid_wlast_queue[wid_wlast_queue.size-1], $time);
  end
  if (bvalid&&bready) begin
    wid_wlast_bresp_queue.push_back(wid_wlast_queue.pop_front());// awid - resp has to come
    // $display("push bid %d %t" , wid_wlast_bresp_queue[wid_wlast_bresp_queue.size-1], $time);
  end
end

//for wstrobe check
always @(negedge aclk)begin
  if (awvalid && awready) begin   // need for awsize and awlen info when data appear on data channel
    wlen_queue.push_back(awlen);  // awlen collected on awvalid&awready - need this for wstrobe check
    wsize_queue.push_back(awsize);// awsize collected on awvalid&awready - need this for wstrobe check
    //$display("push wlen wsize time %d %d %t" , wlen, wsize, $time);
  end
  //need to pop - just on first data    **** -> not every data in burst
  if (wvalid&&wready&&first_or_last_data_flag) begin //first_or_last_data_flag: 1- when wlast and first, 0 for the rest of the transfer
    wlen = wlen_queue.pop_front();  // awlen - specific moment to check - when is last data or first data
    wsize = wsize_queue.pop_front();
    //$display("wlen wsize time %d %d %t" , wlen, wsize, $time);
    first_or_last_data_flag =0;
  end
  if (wvalid&&wready&&wlast) begin 
    if(first_or_last_data_flag)  begin//SINGLE
      wlen = wlen_queue.pop_front();  // awlen - specific moment to check - when is last data or first data
      wsize = wsize_queue.pop_front();
    end
    else
      first_or_last_data_flag =1; //on last data set flag
    
  end
end

function bit [3:0] find_bid(bit [3:0] x); // check if an id on response channel was first on address channel then on data channel then on response channel
  foreach(wid_wlast_bresp_queue[i])
    if(wid_wlast_bresp_queue[i] == x) // need this function because bresp can come out of order
      return wid_wlast_bresp_queue[i];
    return 0;
endfunction

function bit [3:0] find_awid(bit [3:0] x);//Two transactions cannot have the same id if one of them is not finished and resp was not received
  foreach(wid_queue[i])//check if there is in address phase queue (data has not come yet)
    if(wid_queue[i] == x) 
      return wid_queue[i];
    return 0;
endfunction

//***READ CHANNELS***//
//for awlen calculation checker
always @(posedge aclk)begin /// awlen collected on awvalid&awready - need this for awlen calculation
  if (awvalid && awready) begin
    wlen_counter_queue.push_back(awlen+1); // need of a queue: on address phase ids appear faster then data phase proccesses data
  end 
  if (wvalid && wready) begin 
   wlen1 = wlen_counter_queue.pop_front();
   wlen1 = wlen1 - 1;
   wlen_counter_queue.push_back( wlen1); //update value with -1 -> check if on rlast wlen1 == 0 -> all data was transfered
  end 
 end 

 //initialize read queues 
initial begin
  for (int i=0;i<16;i++) begin
    rlen_queue[i] = 0; // arlen collected on arvalid&arready
    pending_rlen_queue[i] = {};// used for when the same id appear on bus and the transfer with the same id is not ready
  end
end


 //for arlen calculation checker and rvalid_violation
always @(posedge aclk)begin
 if (arvalid && arready) begin
     if(rlen_queue[arid]) pending_rlen_queue[arid].push_back(arlen +1);//if there is an arlen with the same id not finished put rlen in pending 
     else rlen_queue[arid] = (arlen + 1'b1); //no transfer with the same id collect arlen
   // $display("rlen arid 1 %d %d %t", rlen_queue[arid], arid, $time);
  end 
  if (rvalid && rready ) begin 
    rlen_queue[rid] --;
    //$display("rlen rid 2 %d %d %t", rlen_queue[rid], rid, $time);
    if(rlen_queue[rid] == 0) 
      if(pending_rlen_queue[rid].size) begin  //if there is an arlen with the same id in pending take it to be decremented in order of appereance
        rlen_queue[rid]=pending_rlen_queue[rid].pop_front();
      end
    //$display("rlen rid 3 %d %d %t", rlen_queue[rid], rid, $time);
  end 
  
end

 //******************************************************************** PROTOCOL ASSERTIONS ************************************************************//
  
// As long a transaction is processed, data should not be X or Z
axi_data_unknown: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) aresetn |-> 
                                                (!$isunknown(awid && awaddr && awlen && awsize && awburst && awvalid && awready && 
                                                             arid && araddr && arlen && arsize && arburst && arvalid && arready && 
                                                             wvalid && wready && wlast && wstrb && wdata &&
                                                             rvalid && rready && rlast && rresp && rdata &&rid &&
                                                             bvalid && bready && bid && bresp)));
                                                             
// Check if xvalid signals after reset are LOW
axi_values_after_reset: assert property( @(posedge aclk) !aresetn ##1 aresetn |-> (!arvalid && !awvalid && !wvalid && !rvalid && !bvalid));
 
// Output values under aresetn
axi_values_reset: assert property(@(posedge aclk) disable iff(aresetn || !has_checks) !aresetn |->
                                                (awid == 'b0 && awaddr == 'b0 && awlen == 'b0 && awsize == 'b0 && awburst == 'b0 && awvalid == 'b0 && awready == 'b0 && 
                                                 arid == 'b0 && araddr == 'b0 && arlen == 'b0 && arsize == 'b0 && arburst == 'b0 && arvalid == 'b0 && arready == 'b0 && 
                                                 wvalid == 'b0 && wready == 'b0 && wlast == 'b0 && wstrb == 'b0 && wdata == 'b0 &&
                                                 rvalid == 'b0 && rready == 'b0 && rlast == 'b0 && rresp == 'b0 && rdata == 'b0 && rid == 'b0 &&
                                                 bvalid == 'b0 && bready == 'b0 && bid == 'b0 && bresp == 'b0 ));
                                     
  
//awaddr, awburst, awid, awlen, awsize must remain stable when awvalid is asserted and awready LOW
axi_awready_signals_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((awvalid == 'b1 && awready == 'b0) |-> ##1 (awaddr == $past(awaddr) 
                                                                                                                                           && awsize == $past(awsize) 
                                                                                                                                           && awburst == $past(awburst) 
                                                                                                                                           && awlen == $past(awlen) 
                                                                                                                                           && awid == $past(awid))));

//araddr, arburst, arid, arlen, arsize must remain stable when arvalid is asserted and arready LOW
axi_arready_signals_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((arvalid == 'b1 && arready == 'b0) |-> ##1 (araddr == $past(araddr) 
                                                                                                                                           && arsize == $past(arsize) 
                                                                                                                                           && arburst == $past(arburst) 
                                                                                                                                           && arlen == $past(arlen) 
                                                                                                                                           && arid == $past(arid))));
//rdata, rid, rresp, rlast must remain stable when rvalid is asserted and rready LOW
axi_rready_signals_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((rvalid == 'b1 && rready == 'b0) |-> ##1 (rdata == $past(rdata) 
                                                                                                                                           && rresp == $past(rresp) 
                                                                                                                                           && rlast == $past(rlast))));
//wdata, wlast, wstrb must remain stable when wvalid is asserted and wready LOW
axi_wready_signals_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((wvalid == 'b1 && wready == 'b0) |-> ##1 (wdata == $past(wdata) 
                                                                                                                                           && wstrb == $past(wstrb) 
                                                                                                                                           && wlast == $past(wlast))));
//bid, bresp must remain stable when bvalid is asserted and bready LOW
axi_bid_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((bvalid == 'b1 && bready == 'b0) |-> ##1 (bresp == $past(bresp) 
                                                                                                                                && bid == $past(bid))));

//Once awvalid is asserted, it must remain asserted until awready is HIGH
axi_awvalid_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((awvalid == 'b1 && awready == 'b0) |-> ##1 (awvalid == 'b1)));

//Once arvalid is asserted, it must remain asserted until arready is HIGH
axi_arvalid_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((arvalid == 'b1 && arready == 'b0) |-> ##1 (arvalid == 'b1)));

//Once wvalid is asserted, it must remain asserted until wready is HIGH
axi_wvalid_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((wvalid == 'b1 && wready == 'b0) |-> ##1 (wvalid == 'b1)));

//Once rvalid is asserted, it must remain asserted until rready is HIGH
axi_rvalid_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((rvalid == 'b1 && rready == 'b0) |-> ##1 (rvalid == 'b1)));

//Once bvalid is asserted, it must remain asserted until beady is HIGH
axi_bvalid_stable: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((bvalid == 'b1 && bready == 'b0) |-> ##1 (bvalid == 'b1)));

//A value of 2’b11 on awburst is not permitted when awvalid is HIGH
axi_awburst_err_reserved: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((awvalid == 'b1) |-> ##1 (awburst != 'b11)));

//A value of 2’b11 on arburst is not permitted when arvalid is HIGH
axi_arburst_err_reserved: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((arvalid == 'b1) |-> ##1 (arburst != 'b11)));

//if axburst == FIXED → axlen == 1
axi_write_fixed_transfer : assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((awburst == 0 && awvalid && awready )  |->  (awlen == 0)));
axi_read_fixed_transfer :  assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((arburst == 0 && arvalid && arready )  |->  (arlen == 0)));

//a WRAP write transfer has an aligned address and has length of 2,4,8,16
axi_write_wrap_transfer: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((awburst == 'b10 && awvalid && awready )  |-> 
                                                                                              ((awlen == 1) || (awlen == 3) || (awlen == 7) || (awlen == 15))));
axi_read_wrap_transfer:  assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((arburst == 'b10 && arvalid && arready )  |-> 
                                                                                              ((arlen == 1) || (arlen == 3) || (arlen == 7) || (arlen == 15))));
                                                                                              
//a write burst cannot cross a 4kb boundary                                                                                              
axi_write_4kb: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks || !four_kb_enable) ((awvalid == 'b1 && awready == 'b1 && awburst == 'b1)  |-> ((awaddr[11:0] + (2**awsize * (awlen+1))) <= 4096)));

//a read burst cannot cross a 4kb boundary                                                                                              
axi_read_4kb: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks || !four_kb_enable) ((arvalid == 'b1 && arready == 'b1  && awburst == 'b1)  |-> ((araddr[11:0] + (2**arsize * (arlen+1))) <= 4096)));

//Cycles are generated correctly based on axlen

axi_write_number_calculation: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks ) ((wvalid == 'b1 && wready == 'b1 && wlast == 'b1 )  |-> wlen_counter_queue.pop_front() == 0)); 

// Two transactions cannot have the same id if one of them is not finished and resp was not received
axi_same_wid_diff_trans: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks ) ((awvalid == 'b1 && awready == 'b1 && find_awid(awid))  |=> (awvalid == 'b0))); 


//This violation can also occur when RVALID is asserted with no preceding AR transfer.
axi_rd_rvalid_violation: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks ) ((rvalid == 'b1)  |-> (rlen_queue.size > 0))); 

//Check if bid is asserted after the last write data handshake is complete & that bid is corresponding with awid. A slave must not take bvalid HIGH until after the last write data handshake is complete
axi_bid_check: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks ) ((bvalid == 'b1 && bready == 'b1 )  |=> (find_bid(bid)==bid))); 

//Write strobes must only be asserted for the correct byte lanes 
axi_wstrb_len_not_0: assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((wvalid == 'b1 && wready == 'b1   && wlen != 'b0)  |-> ( wstrb == 'hF ))); 

axi_wstrb_len_byte:  assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((wvalid == 'b1 && wready == 'b1   && wlen == 'b0 && wsize == 'b0)   |-> ( wstrb == 'h1 || wstrb == 'h2 || wstrb == 'h4 ||wstrb == 'h8 ))); 

axi_wstrb_len_hw  :  assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((wvalid == 'b1 && wready == 'b1   && wlen == 'b0 && wsize == 'b1)   |-> ( wstrb == 'h3 || wstrb == 'hC ))); 

axi_wstrb_len_w   :  assert property(@(posedge aclk) disable iff(!aresetn || !has_checks) ((wvalid == 'b1 && wready == 'b1   && wlen == 'b0 && wsize == 'b10)  |-> ( wstrb == 'hF ))); 

endinterface
`endif