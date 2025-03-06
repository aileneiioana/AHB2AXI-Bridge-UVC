load cov_work/scope/merged_coverage
exec mkdir -p report
report -out report/coverage.rpt -detail -metrics covergroup -all -kind abstract 
