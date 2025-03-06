
# XM-Sim Command File
# TOOL:	xmsim	19.09-s001
#
#
# You can restore this configuration with:
#
#      xrun -uvm +incdir+../src +incdir+../rtl +incdir+../example -access rwc ../example/tb_example.sv +UVM_TESTNAME=test_example_1 -coverage all -covoverwrite -input restore.tcl
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
alias . run
alias quit exit
stop -create -name Randomize -randomize
database -open -shm -into waves.shm waves -default
probe -create -database waves tb_example.ahb_master_if.hclk tb_example.ahb_master_if.hreset_n tb_example.ahb_master_if.hsel tb_example.ahb_master_if.htrans tb_example.ahb_master_if.hreadyout tb_example.ahb_master_if.haddr tb_example.ahb_master_if.hwdata tb_example.ahb_master_if.hwstrobe tb_example.ahb_master_if.hrdata tb_example.ahb_master_if.hresp tb_example.ahb_master_if.hwrite tb_example.ahb_master_if.hburst tb_example.ahb_master_if.hsize tb_example.axi_slave_if.aclk tb_example.axi_slave_if.aresetn tb_example.axi_slave_if.arburst tb_example.axi_slave_if.arlen tb_example.axi_slave_if.arsize tb_example.axi_slave_if.arvalid tb_example.axi_slave_if.arready tb_example.axi_slave_if.araddr tb_example.axi_slave_if.arid tb_example.axi_slave_if.awburst tb_example.axi_slave_if.awlen tb_example.axi_slave_if.awvalid tb_example.axi_slave_if.awready tb_example.axi_slave_if.awaddr tb_example.axi_slave_if.awid tb_example.axi_slave_if.awsize tb_example.axi_slave_if.bvalid tb_example.axi_slave_if.bready tb_example.axi_slave_if.bid tb_example.axi_slave_if.rvalid tb_example.axi_slave_if.rready tb_example.axi_slave_if.rdata tb_example.axi_slave_if.rid tb_example.axi_slave_if.rresp tb_example.axi_slave_if.wvalid tb_example.axi_slave_if.wready tb_example.axi_slave_if.wdata tb_example.axi_slave_if.wlast tb_example.axi_slave_if.wstrb
probe -create -database waves tb_example.axi_slave_if.rlast
probe -create -database waves tb_example.axi_slave_if.bresp

simvision -input restore.tcl.svcf
