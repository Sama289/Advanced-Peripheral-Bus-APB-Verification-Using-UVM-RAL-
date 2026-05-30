package my_driver_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

import my_sequence_item_pkg::*;


class my_driver extends uvm_driver #(my_sequence_item);
	`uvm_component_utils(my_driver)

	my_sequence_item req;
	virtual APB_If APB_vif;

  function new(string name = "my_driver" , uvm_component parent = null);
  		super.new(name , parent);
  endfunction
	

  function void build_phase(uvm_phase phase);
    	super.build_phase(phase);

      `uvm_info("MY_DRIVER" , "DRIVER BUILT" , UVM_LOW);
       req = my_sequence_item::type_id::create("req" , this);

       if(!(uvm_config_db#(virtual APB_If)::get(this, "", "APB_vif", APB_vif))) begin
       	  `uvm_fatal("DRIVER" , "FAILED GETTING INTERFACE");
       end

  endfunction


      
  virtual task run_phase (uvm_phase phase);
        bit [31:0] data;
        APB_vif.presetn <= 1'b1;
        APB_vif.psel <= 0;
        APB_vif.penable <= 0;
        APB_vif.pwrite <= 0;
        APB_vif.paddr <= 0;
        APB_vif.pwdata <= 0;
        forever begin
          seq_item_port.get_next_item (req);
          if (req.pwrite)
            begin
               write();
            end
          else 
            begin   
               read();
            end
            seq_item_port.item_done ();
        end
    endtask  
    
////////////////////////////////////////////////////



    /////write data to dut  -> psel -> pen 
        
    virtual task write();
        @(posedge APB_vif.pclk);
        APB_vif.paddr   <= req.paddr;
        APB_vif.pwdata  <= req.pwdata;
        APB_vif.pwrite  <= 1'b1;
        APB_vif.psel    <= 1'b1;
        @(posedge APB_vif.pclk);
        APB_vif.penable <= 1'b1;
        `uvm_info("DRV", $sformatf("Mode : Write WDATA : %0d ADDR : %0d", APB_vif.pwdata, APB_vif.paddr), UVM_NONE);         
         @(posedge APB_vif.pclk);
        APB_vif.psel    <= 1'b0;
        APB_vif.penable <= 1'b0;
    endtask 
      
     ////read data from dut 
    virtual task read();
        @(posedge APB_vif.pclk);
        APB_vif.paddr   <= req.paddr;
        APB_vif.pwrite  <= 1'b0;
        APB_vif.psel    <= 1'b1;
        @(posedge APB_vif.pclk);
        APB_vif.penable <= 1'b1;
        `uvm_info("DRV", $sformatf("Mode : Write WDATA : %0d ADDR : %0d RDATA : %0d", APB_vif.pwdata, APB_vif.paddr, APB_vif.prdata), UVM_NONE);
        @(posedge APB_vif.pclk);
        APB_vif.psel    <= 1'b0;
        APB_vif.penable <= 1'b0;
        req.prdata   = APB_vif.prdata;
    endtask 


  


endclass 
endpackage