//  APB Adapter
//  Converts UVM register bus operations to APB sequence items w viceversa

package apb_adapter;
  

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_sequence_item_pkg::*;

class apb_adapter extends uvm_reg_adapter;
  `uvm_object_utils(apb_adapter)

  function new(string name = "apb_adapter");
    super.new(name);
    supports_byte_enable = 0; // no strobes
    provides_responses = 0;   // no response channel
  endfunction 

  // -----------------------------------------------------------------------
  //  reg2bus: Converts UVM RAL transaction ( reg op ) -> APB Sequence Item
  //  Called when a register read/write is to be driven onto the bus
  // -----------------------------------------------------------------------
  virtual function uvm_sequence_item reg2bus (const ref uvm_reg_bus_op rw);
    apb_sequence_item tr;
    tr = apb_sequence_item::type_id::create("tr");

    tr.paddr  = rw.addr;
    tr.pwrite = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;
    if (rw.kind == UVM_WRITE) begin
      tr.pwdata = rw.data;
    end

    `uvm_info("APB_ADAPTER",$sformatf(" [reg2bus] SENT TRANSACTION TRANS  :: STATUS :%s| OP = %s | ADDR=0x%0h | DATA=0x%0h |",rw.status.name(), rw.kind.name(), rw.addr, rw.data), UVM_HIGH)
      
    return tr;
  endfunction


  // -----------------------------------------------------------------------
  //  bus2reg: Converts APB Sequence Item -> UVM RAL transaction , ya3ni Register model update
  //  Called after the driver completes the transaction
  // -----------------------------------------------------------------------
      
  virtual function void bus2reg (uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_sequence_item tr;

    if (!$cast(tr, bus_item)) begin
      `uvm_fatal("APB_ADAPTER", " [bus2reg] :: CAST TO APB_SEQ_ITEM FAILED :(")
      return;
    end
    rw.kind = tr.pwrite ? UVM_WRITE : UVM_READ;
    rw.addr = tr.paddr;
    rw.data = tr.pwrite ? tr.pwdata : tr.prdata;
    rw.status = UVM_IS_OK; 

    `uvm_info("APB_ADAPTER", $sformatf("[bus2reg] :: RECEIVED TRANSACTION TRANSLATION STATUS : %s | OP = %s | ADDR=0x%0h | DATA=0x%0h", rw.status.name(), rw.kind.name(), rw.addr, rw.data), UVM_LOW)
    
  endfunction

endclass : apb_adapter

/*

  // ---------------------------------------------------------------------------
  // reg2bus
  // Called by the RAL framework when a register operation (write/read) is
  // initiated.  Translates the generic uvm_reg_bus_op into an APB transaction.
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // bus2reg
  // Called by the RAL framework (or predictor) after the driver completes the
  // APB transaction.  Translates the completed APB item back to uvm_reg_bus_op
  // so the RAL can update its mirrored value.
  // ---------------------------------------------------------------------------

*/

endpackage : apb_adapter