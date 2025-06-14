
# XM-Sim Command File
# TOOL:	xmsim	19.09-s001
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
probe -create -database waves tb_example.aclk tb_example.araddr tb_example.arburst tb_example.aresetn tb_example.arid tb_example.arlen tb_example.arready tb_example.arsize tb_example.arvalid tb_example.awaddr tb_example.awburst tb_example.awid tb_example.awlen tb_example.awready tb_example.awsize tb_example.awvalid tb_example.bid tb_example.bready tb_example.bvalid tb_example.rdata tb_example.rid tb_example.rlast tb_example.rready tb_example.rresp tb_example.rvalid tb_example.wdata tb_example.wlast tb_example.wready tb_example.wstrb tb_example.wvalid

simvision -input /home/ahaldan/Home/AHB2AXI_BRIGE/axi_verification/example/.simvision/3357_ahaldan__autosave.tcl.svcf
