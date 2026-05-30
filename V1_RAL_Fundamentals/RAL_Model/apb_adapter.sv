//  APB Adapter
//  Converts UVM register bus operations to APB sequence items w viceversa
import uvm_pkg::*;
`include "uvm_macros.svh"
import my_sequence_item_pkg::*;

  class apb_adapter extends uvm_reg_adapter;
    `uvm_object_utils(apb_adapter)

    function new(string name = "apb_adapter");
      super.new(name);
      supports_byte_enable = 0;  // APB does not support byte enables
      provides_responses   = 0;  // Driver does not send separate response elhamdulilah :)
    endfunction

    // -----------------------------------------------------------------------
    //  reg2bus: Register op ->  APB sequence item
    //  Called when a register read/write is to be driven onto the bus
    // -----------------------------------------------------------------------
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      my_sequence_item seq_item;
      seq_item = my_sequence_item::type_id::create("seq_item");

      seq_item.paddr  = rw.addr;
      seq_item.pwdata = rw.data;
      seq_item.pwrite = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;

      `uvm_info("APB_ADAPTER",$sformatf("[reg2bus] %-5s  ADDR=0x%0h  DATA=0x%0h",rw.kind.name(), rw.addr, rw.data), UVM_HIGH)
      
      return seq_item;
    endfunction

    // -----------------------------------------------------------------------
    //  bus2reg: APB sequence item -> Register model update
    //  Called after the driver completes the transaction
    // -----------------------------------------------------------------------
    virtual function void bus2reg(uvm_sequence_item bus_item,ref uvm_reg_bus_op rw);
      my_sequence_item seq_item;
      if (!$cast(seq_item, bus_item)) begin
        `uvm_fatal("APB_ADAPTER","bus2reg: Failed to cast bus_item to my_sequence_item")
      end
      rw.kind   = seq_item.pwrite ? UVM_WRITE : UVM_READ;
      rw.addr   = seq_item.paddr;
      rw.data   = seq_item.pwrite ? seq_item.pwdata : seq_item.prdata;
      rw.status = UVM_IS_OK;

      `uvm_info("APB_ADAPTER",$sformatf("[bus2reg] %-5s  ADDR=0x%0h  DATA=0x%0h",rw.kind.name(), rw.addr, rw.data), UVM_HIGH)
    endfunction

  endclass : apb_adapter
