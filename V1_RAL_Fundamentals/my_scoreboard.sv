package my_scoreboard_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_sequence_item_pkg::*;


class my_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(my_scoreboard)

virtual APB_If APB_vif;
my_sequence_item seq_item; 
uvm_analysis_export #(my_sequence_item) sco_ap;
uvm_tlm_analysis_fifo #(my_sequence_item) sb_fifo;

logic [31:0] Assoc_Array [bit[31:0]] ;

  function new (string name = "my_scoreboard" , uvm_component parent = null);
     super.new(name , parent);
     sco_ap = new("sco_ap" , this);
     seq_item = new("seq_item");
     sb_fifo = new("sb_fifo",this);
  endfunction

  
  function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      `uvm_info("my_scoreboard" , "SCO BUILT" , UVM_LOW);     
        
       if(!(uvm_config_db#(virtual APB_If)::get(this, "", "APB_vif", APB_vif))) begin
           `uvm_fatal("SCO" , "FAILED GETTING INTERFACE");
       end
  endfunction


   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      sco_ap.connect(sb_fifo.analysis_export);
    endfunction
  


  task run_phase(uvm_phase phase);
    forever begin
     sb_fifo.get(seq_item);
       @(posedge  APB_vif.pclk);
         if(seq_item.psel && seq_item.penable && APB_vif.presetn) begin
            if(APB_vif.pwrite) begin
                Assoc_Array[seq_item.paddr] = seq_item.pwdata;
            end
            else begin
                 if(seq_item.prdata == Assoc_Array[seq_item.paddr]) begin
                     `uvm_info("RIGHT DATA" , $sformatf("rdata = %0h , Expec_rdata = %0h", seq_item.prdata,Assoc_Array[seq_item.paddr]) , UVM_LOW);          
                 end
                 else begin
                     `uvm_info("WRONG DATA" , $sformatf("rdata = %0h , Expec_rdata = %0h", seq_item.prdata,Assoc_Array[seq_item.paddr]) , UVM_LOW);          
                 end
            end
         end 
    end
  endtask    

endclass


endpackage