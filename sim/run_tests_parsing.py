#!/usr/bin/python

import os
import random
import sys
  
  
  

      
class run_tests:
  
  def __init__(self):
    self.quotes = '"'
    self.verb="UVM_MEDIUM"
    self.seed=12264
    self.test_name_list=[]
    self.uvcs_src_vsrc_rtl_loc=" +incdir+../src +incdir+../rtl +incdir+../example -access rwc ../example/tb_example.sv " 
    self.tests_name_file="tests_name.txt"
    self.gui=""
    self.seed_list=[]
    self.nr_regression=15
        
  def read_tests_name_file(self):
    fileName = self.tests_name_file
    fileName = "./" + fileName
    while (not os.path.exists(fileName)):
      self.gui="-gui " 
      os.system(self.run_test_string(self.tests_name_file,self.seed))
      return 0;
    
    self.verb="UVM_NONE"   
    
    with open(self.tests_name_file) as f:
      while True:
        test_name = f.readline()
        if not test_name:
          break
        self.test_name_list.append(test_name) 
       
    for i,item in enumerate(self.test_name_list):
      test_name=self.test_name_list[i]
      print(test_name)
      test_name=test_name.strip('\n')
      test_name=test_name.strip()
      test_name_split=test_name.split()
      
      if len(test_name_split)==2:
        self.seed_list.append(test_name_split[1])
      else:
        self.seed_list.append(None)
  
      self.test_name_list[i]=test_name_split[0]
      
    return 1;
  
  def remove_create_logs(self):
    os.system("rm -f -r logs")
    os.system("mkdir logs")
     
    
  def run_test(self):
   
    for i,item in enumerate(self.seed_list):
      if self.seed_list[i]==None:
        self.seed=str(random.randint(10000,32000))
        self.seed_list[i]=self.seed

      else:
        self.seed=self.seed_list[i]

      os.system(self.run_test_string(self.test_name_list[i],self.seed))
    list_length=len(self.test_name_list)
    for k in range(0,self.nr_regression):
      
      for i in range(0,list_length):
        self.seed=str(random.randint(10000, 32000))
        self.test_name_list.append(self.test_name_list[i])
        self.seed_list.append(self.seed)
        
        os.system(self.run_test_string(self.test_name_list[i],self.seed))
      
    os.system("grep -H 'UVM_ERROR :' logs/*.log >> error_file")

    os.system("grep -H 'UVM_FATAL :' logs/*.log >> fatal_file")
    
  def run_test_string(self,test_name,seed):
    run_test_no_gui=("xrun -uvm "+self.gui+ "-seed " 
+ seed + 
" -access +rwc -l logs/" 
+ test_name + "_" + seed + 
".log -coverage a -covdesign apb -covoverwrite -covtest "
+ test_name + "_" + seed + self.uvcs_src_vsrc_rtl_loc+ 
"-timescale 1ns/1ns +UVM_TESTNAME="
+ test_name + 
" +UVM_VERBOSITY=" 
+ self.verb)
    return run_test_no_gui
  
    
    
  def merge_command_func(self):
    merge="merge"
    for test_name in self.test_name_list:
      merge=merge+" cov_work/apb/" + test_name + "_?????"

    merge=merge+" -out merged_coverage"
    merge=merge+" -overwrite"

    merge_command="imc -execcmd " + self.quotes + merge + self.quotes  
    os.system(merge_command)
  
  def report(self):
    report=("load cov_work/scope/merged_coverage\n"
    "exec mkdir -p report\n"
    "report -out report/coverage.rpt -detail -metrics covergroup -all -kind abstract\n")

    report_command="imc -execcmd " + self.quotes+report+self.quotes

    os.system(report_command)

  def report_html(self):   
    report=("load cov_work/scope/merged_coverage\n"
    "exec mkdir -p report_html\n"
    "report -out report_html/coverage.html -detail -html \n")

    report_command="imc -execcmd " + self.quotes+report+self.quotes

    os.system(report_command)
  
  def write_file(self):
    
    f = open("tests_used.txt", "w")
    for i in range(0, len(self.test_name_list)):
      f.write(self.test_name_list[i]+" "+ str(self.seed_list[i]))
      f.write("\n" )
      
   
    f.close()  
    
  def set_test_name_file(self,tests_name):
    if len(tests_name)!=0:  
      self.tests_name_file=tests_name
      
  def set_seed(self,seed):
    if seed!=None:  
      self.seed=seed 
      
  def set_nr_regression(self,reg_nr):
    if reg_nr!=None:  
      self.nr_regression=int(reg_nr)
      
        
  def set_loc(self,loc):
    line_list=[]
    if len(loc)!=0:  
      with open(loc) as f:
        while True:
          line = f.readline()
          line_list.append(line)   
          if not line:
            break
      del line_list[-1:]
      line_fin=" "
      for i in range(0, len(line_list)):
        print(line)
        line=line_list[i]
        line=line.strip('\n')
        line=line.strip()
        line_fin=line_fin+line
        line_fin=line_fin.replace("\\", "")
      self.uvcs_src_vsrc_rtl_loc=line_fin
      
      print(self.uvcs_src_vsrc_rtl_loc)
    
 
def main():
    test_name=sys.argv[1]
    
    if len(sys.argv)==3:
      seed=sys.argv[2]
      nr_reg=sys.argv[2]
    else:
      seed=0
      nr_reg=5
        
    rs=run_tests()
    rs.set_seed(seed)
    rs.set_test_name_file(test_name)
    rs.remove_create_logs()
    if not rs.read_tests_name_file()==0: 
      rs.set_nr_regression(nr_reg)
      rs.run_test()
      rs.merge_command_func()
      rs.report()
      rs.write_file() 
    
main()

#How to use it
#write in the command line
#python run_tests_parsing.py [test_name/text file that contains many test names with seeds or withouth seeds] [seed only when you use only one test]
#the seed in the text file must be between 10000 32000
#text file must contain more than one name
