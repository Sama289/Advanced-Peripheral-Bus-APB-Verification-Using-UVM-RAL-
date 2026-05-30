package my_monitor_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_sequence_item_pkg::*;


class my_monitor extends uvm_monitor;
  `uvm_component_utils(my_monitor)

virtual APB_If APB_vif;
my_sequence_item seq_item; 
uvm_analysis_port #(my_sequence_item) mon_ap;

  function new (string name = "my_monitor" , uvm_component parent = null);
     super.new(name , parent);
     mon_ap = new("mon_ap" , this);
  endfunction

  
  function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      `uvm_info("MY_MONITOR" , "MONITOR BUILT" , UVM_LOW);     

       if(!(uvm_config_db#(virtual APB_If)::get(this, "", "APB_vif", APB_vif))) begin
           `uvm_fatal("MON" , "FAILED GETTING INTERFACE");
       end

  endfunction
  

  task run_phase(uvm_phase phase);
     
         
            forever begin
               my_sequence_item seq_item = my_sequence_item::type_id::create("seq_item");
               @(posedge APB_vif.pclk);

                 seq_item.paddr = APB_vif.paddr;
                 seq_item.pwdata= APB_vif.pwdata;
                 seq_item.prdata=APB_vif.prdata;
                 seq_item.psel  = APB_vif.psel;
                 seq_item.pwrite= APB_vif.pwrite;
                 seq_item.penable= APB_vif.penable;
                 mon_ap.write(seq_item);
                
            end
        
    endtask    

endclass


endpackage