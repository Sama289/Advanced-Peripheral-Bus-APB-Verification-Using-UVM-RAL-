package my_monitor_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_sequence_item_pkg::*;


class my_monitor extends uvm_monitor;
  `uvm_component_utils(my_monitor)

virtual APB_If APB_vif;
apb_sequence_item seq_item; 
uvm_analysis_port #(apb_sequence_item) mon_ap;

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
  

  // task run_phase(uvm_phase phase);
     
         
  //           forever begin
  //              apb_sequence_item seq_item = apb_sequence_item::type_id::create("seq_item");
  //              @(posedge APB_vif.pclk);

  //                seq_item.paddr = APB_vif.paddr;
  //                seq_item.pwdata= APB_vif.pwdata;
  //                seq_item.prdata=APB_vif.prdata;
  //                seq_item.psel  = APB_vif.psel;
  //                seq_item.pwrite= APB_vif.pwrite;
  //                seq_item.penable= APB_vif.penable;
  //                mon_ap.write(seq_item);
                
  //           end
        
  //   endtask  

// This sends exactly one item per transaction.
// -> Writes are captured immediately.
// ->Reads are captured one clock later when the data is valid.
task run_phase(uvm_phase phase);
    forever begin
        apb_sequence_item seq_item = apb_sequence_item::type_id::create("seq_item");
        @(posedge APB_vif.pclk);

        if (APB_vif.psel && APB_vif.penable) begin
            seq_item.paddr   = APB_vif.paddr;
            seq_item.pwdata  = APB_vif.pwdata;
            seq_item.pwrite  = APB_vif.pwrite;
            seq_item.psel    = APB_vif.psel;
            seq_item.penable = APB_vif.penable;

            if (APB_vif.pwrite) begin
                // WRITE: data valid now
                seq_item.prdata = APB_vif.prdata;
                mon_ap.write(seq_item);
            end
            else begin
                // READ: DUT rdata_tmp was just triggered this edge
                // prdata becomes valid at next posedge (Edge D)
                @(posedge APB_vif.pclk);
                seq_item.prdata = APB_vif.prdata; // CORRECT -> after DUT NBA settled
                mon_ap.write(seq_item);
            end
        end
    end
endtask

endclass


endpackage