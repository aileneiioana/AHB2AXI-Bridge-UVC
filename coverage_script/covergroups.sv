// Scope: AHB
covergroup ahb_busy_cov @ahb_busy_cov_e;
  BUSY_after_NONSEQ_sig                   : coverpoint BUSY_after_NONSEQ;
  BUSY_after_BUSY_sig                     : coverpoint BUSY_after_BUSY;
  BUSY_after_SEQ_sig                      : coverpoint BUSY_after_SEQ;
  BUSY_before_SEQ_and_not_last_sig        : coverpoint BUSY_before_SEQ_and_not_last;
  BUSY_before_SEQ_and_last_sig            : coverpoint BUSY_before_SEQ_and_last;
  op_type_sig                             : coverpoint vif.hwrite;
  BUSY_after_NONSEQ_cross_op_type         : cross op_type_sig, BUSY_after_NONSEQ_sig;
  BUSY_after_BUSY_cross_op_type             : cross op_type_sig, BUSY_after_BUSY_sig;
  BUSY_after_SEQ_cross_op_type              : cross op_type_sig, BUSY_after_SEQ_sig;
  BUSY_before_SEQ_and_not_last_cross_op_type: cross op_type_sig, BUSY_before_SEQ_and_not_last_sig;
  BUSY_before_SEQ_and_last_cross_op_type    : cross op_type_sig, BUSY_before_SEQ_and_last_sig;
endgroup

// Scope: AHB
covergroup ahb_checkers_cov @ahb_checkers_cov_e;
  seq_transfer_check                        : coverpoint seq_transfer_check_sig;
  busy_transfer_check_seq:                   : coverpoint busy_transfer_check_seq_sig ;;
  busy_transfer_check                       : coverpoint busy_transfer_check_sig;
  idle_transfer_check                       : coverpoint idle_transfer_check_sig;
  stable_data_check                         : coverpoint stable_data_check_sig;
  hburst_transfer_check_4                 : coverpoint hburst_transfer_check_4_sig;
  hburst_transfer_check_8                 : coverpoint hburst_transfer_check_8_sig;
  hburst_transfer_check_16                : coverpoint hburst_transfer_check_16_sig;
  address_calculated_correctly_INCR4_check  : coverpoint address_calculated_correctly_INCR4;
  address_calculated_correctly_INCR8_check  : coverpoint address_calculated_correctly_INCR8;
  address_calculated_correctly_INCR16_check : coverpoint address_calculated_correctly_INCR16;
  address_calculated_correctly_WRAP4_check  : coverpoint address_calculated_correctly_WRAP4;
  address_calculated_correctly_WRAP8_check  : coverpoint address_calculated_correctly_WRAP8;
  address_calculated_correctly_WRAP16_check : coverpoint address_calculated_correctly_WRAP16;
endgroup

// Scope: AHB
covergroup ahb_reset_cov @ahb_reset_cov_e;
  hreset_sig                              : coverpoint hreset;
endgroup

// Scope: AHB
covergroup ahb_signal_cov @ahb_signal_cov_e;
  hsel_sig                                : coverpoint  vif.hsel     ;
  hwrite_sig                              : coverpoint  vif.hwrite   ;
  hreadyout_sig                           : coverpoint  vif.hreadyout;
  hresp_sig                               : coverpoint  vif.hresp    ;
  htrans_sig                              : coverpoint  vif.mon_cb.htrans   ;
  hburst_sig                              : coverpoint  vif.hburst  {
    bins SINGLE = {'b000};
    bins WRAP4 = {'b010};
    bins INCR4 = {'b011};
    bins WRAP8 = {'b100};
    bins INCR8 = {'b101};
    bins WRAP16 = {'b110};
    bins INCR16 = {'b111};
  }
  hsize_sig                               : coverpoint vif.hsize {
    bins BYTE = {'b000};
    bins HWROD = {'b001};
    bins WORD = {'b010};
  }
  hstrobe_sig                             : coverpoint vif.hwstrobe;
  read_write_with_and_no_err              : cross hwrite_sig, hresp_sig;
  all_types                               : cross hwrite_sig, hburst_sig, hsize_sig;
endgroup

// Scope: AHB
covergroup ahb_trans_cov @ahb_trans_cov_e;
  transaction_delay                       : coverpoint trans.ahb_trans_delay {
    bins b2b = {0};
    bins one = {1};
    bins short = {[ 1: 5]};
    bins long = {[11:19]};
  }
  hready_delay                            : coverpoint trans.ahb_ready_delay {
    bins b2b = {0};
    bins one = {1};
    bins short = {[ 1: 5]};
    bins long = {[11:19]};
  }
  busy_cycles                             : coverpoint trans.busy_cycles {
    bins no_busy = {0};
    bins short_busy = {[ 1: 5]};
    bins long_busy = {[11:19]};
  }
endgroup

// Scope: AHB
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

// Scope: AHB
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

// Scope: AXI
covergroup axi_delay_cov @axi_delay_cov_e;
  delay_between_waddr_c                   : coverpoint delay_between_waddr {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_raddr_c                   : coverpoint delay_between_raddr {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_waddr_wdata_c             : coverpoint delay_between_waddr_wdata {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_waddr_bresp_c             : coverpoint delay_between_waddr_bresp {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_raddr_rdata_c             : coverpoint delay_between_raddr_rdata {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_raddr_rresp_c             : coverpoint delay_between_raddr_rresp {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_bresp_c                   : coverpoint delay_between_bresp {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_arvalid_c                 : coverpoint delay_between_arvalid {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_awvalid_c                 : coverpoint delay_between_awvalid {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_rvalid_c                  : coverpoint delay_between_rvalid {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_arvalid_arready_c         : coverpoint delay_between_arvalid_arready {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_awvalid_awready_c         : coverpoint delay_between_awvalid_awready {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_rvalid_rready_c           : coverpoint delay_between_rvalid_rready {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_wvalid_wready_c           : coverpoint delay_between_wvalid_wready {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
  delay_between_bvalid_bready_c           : coverpoint delay_between_bvalid_bready {
    bins one = {1};
    bins short = {[ 1: 5]};
  }
endgroup

// Scope: AXI
covergroup axi_signal_cov @axi_signal_cov_e;
  awid_sig                                : coverpoint vif.awid    ;
  awvaid_sig                              : coverpoint vif.awvalid ;
  awready_sig                             : coverpoint vif.awready ;
  arid_sig                                : coverpoint vif.arid    ;
  arvaid_sig                              : coverpoint vif.arvalid ;
  arready_sig                             : coverpoint vif.arready ;
  wvaid_sig                               : coverpoint vif.wvalid  ;
  wready_sig                              : coverpoint vif.wready  ;
  wlast_sig                               : coverpoint vif.wlast   ;
  rid_sig                                 : coverpoint vif.rid     ;
  rready_sig                              : coverpoint vif.rready  ;
  rvaid_sig                               : coverpoint vif.rvalid  ;
  rlast_sig                               : coverpoint vif.rlast   ;
  bid_sig                                 : coverpoint vif.bid     ;
  bvaid_sig                               : coverpoint vif.bvalid  ;
  bready_sig                              : coverpoint vif.bready  ;
  awlen_sig                               : coverpoint vif.awlen   ;
  arlen_sig                               : coverpoint vif.awlen   ;
  bresp_sig                               : coverpoint vif.rresp {
    bins AXI_OKAY = {'b000};
    bins AXI_EXOKAY = {'b001};
    bins AXI_SLVERR = {'b010};
    bins AXI_DECERR = {'b011};
  }
  rresp_sig                               : coverpoint vif.bresp {
    bins AXI_OKAY = {'b000};
    bins AXI_EXOKAY = {'b001};
    bins AXI_SLVERR = {'b010};
    bins AXI_DECERR = {'b011};
  }
  arburst_sig                             : coverpoint vif.awburst {
    bins FIXED = {'b000};
    bins INCR = {'b001};
    bins WRAP = {'b010};
  }
  awburst_sig                             : coverpoint vif.arburst {
    bins FIXED = {'b000};
    bins INCR = {'b001};
    bins WRAP = {'b010};
  }
  awsize_sig                              : coverpoint vif.awsize {
    bins BYTE = {'b000};
    bins HWROD = {'b001};
    bins WORD = {'b010};
  }
  arsize_sig                              : coverpoint vif.arsize {
    bins BYTE = {'b000};
    bins HWROD = {'b001};
    bins WORD = {'b010};
  }
  wstrobe_sig                             : coverpoint vif.wstrb;
  awvalid_awready_cp                      : cross awvaid_sig, awready_sig;
  arvalid_arready_cp                      : cross arvaid_sig, arready_sig;
  wvalid_wready_cp                        : cross wvaid_sig,  wready_sig;
  wvalid_wready_wlast_cp                  : cross wvaid_sig,  wready_sig, wlast_sig {
    ignore_bins wvalid_wready_wlast_cp_ig0 = binsof(wvaid_sig)  intersect {0};
    ignore_bins wvalid_wready_wlast_cp_ig1 = binsof(wready_sig) intersect {0};
    ignore_bins wvalid_wready_wlast_cp_ig2 = binsof(wlast_sig)  intersect {0};
  }
  rvalid_rready_cp                        : cross rvaid_sig,  rready_sig {
    ignore_bins rvalid_rready_cp_ig0 = binsof(wvaid_sig)  intersect {0};
    ignore_bins rvalid_rready_cp_ig1 = binsof(wready_sig) intersect {0};
    ignore_bins rvalid_rready_cp_ig2 = binsof(wlast_sig)  intersect {0};
  }
  rvalid_rready_rlast_cp                  : cross rvaid_sig,  rready_sig, rlast_sig {
    ignore_bins rvalid_rready_rlast_cp_ig0 = binsof(rvaid_sig)  intersect {0};
    ignore_bins rvalid_rready_rlast_cp_ig1 = binsof(rready_sig) intersect {0};
    ignore_bins rvalid_rready_rlast_cp_ig2 = binsof(rlast_sig)  intersect {0};
  }
  rready_rresp_cp                         : cross rready_sig, rresp_sig {
    ignore_bins rready_rresp_cp_ig0 = binsof(rready_sig)  intersect {0};
  }
  bvalid_bready_cp                        : cross bvaid_sig,  bready_sig;
  bready_bresp_cp                         : cross bready_sig, bresp_sig {
    ignore_bins bready_bresp_cp_ig0 = binsof(bready_sig)  intersect {0};
  }
  axi_cross_write_transfer_cp             : cross awsize_sig, awburst_sig;
  axi_cross_read_transfer_cp              : cross arsize_sig, arburst_sig;
endgroup

// Scope: AXI
covergroup rdata_toggle_cov with function sample_wdata(bit[DW-1:0] data, int pos);
  toggle_rdata : coverpoint data[pos] {
    bins zeroone = (0 => 1);
    bins onezero = (1 => 0);
  }
endgroup

function void sample_wdata(bit[DW-1:0] data);
  for(int i = 0; i < DW; i++) begin
    rdata_toggle_cov.sample(data, i);
  end
endfunction

// Scope: AXI
covergroup transfer_cov @vif.mon_cb;
  write_outstanding_covered_sig           : coverpoint write_outstanding_covered;
  read_outstanding_covered_sig            : coverpoint read_outstanding_covered;
  write_out_of_order_covered_sig          : coverpoint write_out_of_order_covered;
  read_out_of_order_covered_sig           : coverpoint read_out_of_order_covered;
  write_in_order_covered_sig              : coverpoint write_in_order_covered;
  read_in_order_covered_sig               : coverpoint read_in_order_covered;
  read_data_interleaving_covered_sig      : coverpoint read_data_interleaving_covered;
endgroup

// Scope: AXI
covergroup wdata_toggle_cov with function sample_wdata(bit[DW-1:0] data, int pos);
  toggle_wdata : coverpoint data[pos] {
    bins zeroone = (0 => 1);
    bins onezero = (1 => 0);
  }
endgroup

function void sample_wdata(bit[DW-1:0] data);
  for(int i = 0; i < DW; i++) begin
    wdata_toggle_cov.sample(data, i);
  end
endfunction

// Scope: Bridge
covergroup adress_space_cg @adress_space_cg_e;
  incr4_addr_split_c                      : coverpoint master_trans.start_addr[11:0];
  incr8_addr_split_c                      : coverpoint master_trans.start_addr[11:0];
  incr16_addr_split_c                     : coverpoint master_trans.start_addr[11:0];
  burst_c                                 : coverpoint master_trans.ahb_burst_type;
  incr4_SPLIT_cp                          : cross incr4_addr_split_c,  burst_c {
    ignore_bins incr4_SPLIT_cp_ig0 = binsof(burst_c) intersect {SINGLE, WRAP4, INCR8, INCR16, WRAP8,WRAP16};};
  }
  incr8_SPLIT_cp                          : cross incr8_addr_split_c,  burst_c {
    ignore_bins incr8_SPLIT_cp_ig0 = binsof(burst_c) intersect {SINGLE, WRAP4, INCR4, INCR16, WRAP8,WRAP16};};
  }
  incr16_SPLIT_cp                         : cross incr16_addr_split_c,  burst_c {
    ignore_bins incr16_SPLIT_cp_ig0 = binsof(burst_c) intersect {SINGLE, WRAP4, INCR8, INCR4, WRAP8,WRAP16};};
  }
  data_space                              : coverpoint adress_space;
endgroup

// Scope: Bridge
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

// Scope: Bridge
covergroup ctrl_cov @ctrl_cov_e;
  wrap_value_c                            : coverpoint ctrl_value[1];
  outstanding_value_c                     : coverpoint ctrl_value[0];
  max_outstandung_value_c                 : coverpoint ctrl_value[13:8];
  reserved1_value_c                       : coverpoint  ctrl_value[7:2];
  reserved2_value_c                       : coverpoint ctrl_value[31:14];
  outstanding_cp                          : cross outstanding_value_c, max_outstandung_value_c {
    ignore_bins outstanding_cp_ig0 = binsof(outstanding_value_c)  intersect {0};
  }
  wrap_en_outstanding_cp                  : cross wrap_value_c, outstanding_cp;
  reserved_cp                             : cross reserved1_value_c, reserved2_value_c {
    ignore_bins reserved_cp_ig0 = binsof(reserved1_value_c)  intersect {[1:31]};
    ignore_bins reserved_cp_ig1 = binsof(reserved2_value_c)  intersect {[1:131071]};
  }
endgroup

// Scope: Exemplu
covergroup coverage_group_name @event_name;
  coverpointX                             : coverpoint mydataX;
  coverpointY                             : coverpoint mydataY;
  coverpoint ignores                      : cross mydataX, mydataY {
    illegal_bins coverpoint ignores_il0 = binsof(mydataX)  intersect {0};
  }
  coverpoint ignoreXX                     : cross mydataX, mydataY {
    illegal_bins coverpoint ignoreXX_il0 = binsof(mydataY) intersect {3} && binsof(mydataX) intersect {1, 2, 3};
  }
  coverpoint ignoreXy                     : cross mydataX, mydataY {
    ignore_bins coverpoint ignoreXy_ig0 = binsof(mydataY) intersect {6} &&  binsof(mydataX) intersect {4};
  }
endgroup

