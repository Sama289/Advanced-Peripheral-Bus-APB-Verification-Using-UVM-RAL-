//  APB Register Block
//  Instantiates all registers and maps them to APB address space
package apb_reg_block_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"
import my_ral_pkg::*;

   class apb_reg_block extends uvm_reg_block;
    `uvm_object_utils(apb_reg_block)

    // ---- Register Instances ----
    rand cntrl_reg CNTRL;
    rand reg1_reg  REG1;
    rand reg2_reg  REG2;
    rand reg3_reg  REG3;
    rand reg4_reg  REG4;

    // ---- Default Map ----
    uvm_reg_map default_map;

    function new(string name = "apb_reg_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      // ---- Create Register Instances ----
      CNTRL = cntrl_reg::type_id::create("CNTRL");
      REG1  = reg1_reg ::type_id::create("REG1");
      REG2  = reg2_reg ::type_id::create("REG2");
      REG3  = reg3_reg ::type_id::create("REG3");
      REG4  = reg4_reg ::type_id::create("REG4");

      // ---- Build internal fields ----
      CNTRL.build();
      REG1 .build();
      REG2 .build();
      REG3 .build();
      REG4 .build();

      // // ---- Configure: (parent_block, reg_file, hdl_path)
      // //HDL paths enable backdoor (poke/peek) access
      // CNTRL.configure(this, null, "top.DUT.cntrl");
      // REG1 .configure(this, null, "top.DUT.reg1");
      // REG2 .configure(this, null, "top.DUT.reg2");
      // REG3 .configure(this, null, "top.DUT.reg3");
      // REG4 .configure(this, null, "top.DUT.reg4");
      
      // ---- Configure: (parent_block, reg_file, hdl_path)
      // HDL paths enable backdoor (poke/peek) access
      CNTRL.configure(this, null, "cntrl");
      REG1 .configure(this, null, "reg1");
      REG2 .configure(this, null, "reg2");
      REG3 .configure(this, null, "reg3");
      REG4 .configure(this, null, "reg4");
      
      // ---- Create Address Map ----
      // create_map(name, base_addr, n_bytes, endian, byte_addr)
      default_map = create_map("default_map", 32'h0, 4, UVM_LITTLE_ENDIAN, 0);

      // ---- Add Registers to Map ----
      // add_reg(reg, offset, rights)
      default_map.add_reg(CNTRL, 32'h00, "RW");
      default_map.add_reg(REG1,  32'h04, "RW");
      default_map.add_reg(REG2,  32'h08, "RW");
      default_map.add_reg(REG3,  32'h0C, "RW");
      default_map.add_reg(REG4,  32'h10, "RW");

      // ---- Lock model (no more changes allowed) ----
      lock_model();
    endfunction

  endclass : apb_reg_block
   

endpackage : apb_reg_block_pkg
