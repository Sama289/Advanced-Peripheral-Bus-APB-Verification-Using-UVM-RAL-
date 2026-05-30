package apb_reg_block_pkg;
//  APB Register Block
//  Instantiates all registers and maps them to APB address space

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_regs_pkg::*;


  class top_reg_block extends uvm_reg_block; // REGISTER BLOCK 
      `uvm_object_utils(top_reg_block)  

     // ---- Instances of my regs that extend from uvm_reg ---
     // rand so block-level randomize() cascades to every rand uvm_reg_field.   
      rand cntrl_reg cntrl_inst;
      rand reg1  reg1_inst;
      rand reg2  reg2_inst;
      rand reg3  reg3_inst;
      rand reg4  reg4_inst;


     // ---- constructor ----  
      function new(string name = "top_reg_block");
          super.new(name,UVM_NO_COVERAGE);
          // bec we Do not build any block-level coverage L EL-TOP block
      endfunction : new 
    

     // ---- create,build and configure each register ----   
     virtual function void build();

        // ---- Step 1 : Create register instances via UVM factory  ----
        cntrl_inst = cntrl_reg::type_id::create("cntrl_inst");
        reg1_inst  = reg1::type_id::create("reg1_inst");
        reg2_inst  = reg2::type_id::create("reg2_inst");
        reg3_inst  = reg3::type_id::create("reg3_inst");
        reg4_inst  = reg4::type_id::create("reg4_inst");

        // ---- Step 2 : configure(parent_block, parent_regfile, for backdoor (name in design ) hdl_path_suffix)  ----
        cntrl_inst.configure(this, null, "cntrl");
        reg1_inst.configure(this, null, "reg1");
        reg2_inst.configure(this, null, "reg2");
        reg3_inst.configure(this, null, "reg3");
        reg4_inst.configure(this, null, "reg4");

        // ---- Step 3 : Build register fields ----
        cntrl_inst.build();
        reg1_inst.build();
        reg2_inst.build();
        reg3_inst.build();
        reg4_inst.build();

        // ---- Step 4 : Create APB address map ----
        // create_map(name, base_addr, n_bytes, endian, byte_addr)
        default_map = create_map("APB_map", 'h0, 4, UVM_LITTLE_ENDIAN, 1);

        // ---- Step 5 : Add registers to map -----
        // add_reg(reg, offset, access)
        default_map.add_reg(cntrl_inst, 'h00, "RW");
        default_map.add_reg(reg1_inst, 'h04, "RW");
        default_map.add_reg(reg2_inst, 'h08, "RW");
        default_map.add_reg(reg3_inst, 'h0C, "RW");
        default_map.add_reg(reg4_inst, 'h10, "RW");


           
        // ---- Lock model (no more changes allowed) ----
        // lock_model(); already locked in test 

        `uvm_info("APB_REG_BLOCK","\n Register block built and locked (5 regs )\n", UVM_LOW)
      endfunction 
    
    
  endclass

endpackage : apb_reg_block_pkg

//--------------- REMINDERS FOR ME ----------------------------
// Instantiates all registers (crate , configure and build)

// note : If you override build() and call get_parent(), you'll get null since block link isn't set yet 
// this is why the order is : Step 1: Create -> Step 2: Configure (set parent block FIRST) -> Step 3: Build fields (now parent is known)
// maps regs to APB address space

// BUILD ORDER ::
//    create -> configure -> build(fields) -> create_map ->
//    add_reg -> add_hdl_path_slice -> lock_model

// CONFIGURE:
//  configure(parent_block, parent_regfile, hdl_path_suffix)
//  parent_regfile = null  ->  3shan no regfile layer in this version
//  hdl_path_suffix= ""   ->  explicit slices added in step 5

// MAPPING :
//  Name of map, base_addr(start), size (Lhoa Bus Width in Bytes / transaction size ), Endianness ( bus lanes mapping), Offset 

// OFFSET :
//  1 (Byte Addressing): Every single byte has its own address. Since your bus is 4 bytes wide, the addresses will step by 4: 0x00, 0x04, 0x08, 0x0C. (zy el-AXI).
//  0 (Word Addressing): Every full 32-bit word gets just one address increment. The steps would be: 0x00, 0x01, 0x02, 0x03.

// little endian : (Least Significant Byte goes to the lowest address) : )

// FOR BACKDOOR :
// OPTION 1 :
//    configure() suffix already gives you the path via block prefix
//    cntrl_inst.configure(this, null, "cntrl"); 
//    Step 6 → DELETE entirely

// OPTION 2 :
//    cntrl_inst.configure(this, null, "");  // empty suffix
//    cntrl_inst.add_hdl_path_slice("cntrl", 0, 4); // relative only
//    AND remove reg_model.add_hdl_path("top.DUT") from test
//    AND MAKE STEP 6 :
      // add_hdl_path_slice("path", lsb, size/width ya3ni )
      // cntrl_inst.add_hdl_path_slice("top.DUT.cntrl", 0, 4);
      // reg1_inst.add_hdl_path_slice("top.DUT.reg1",   0, 32);
      // reg2_inst.add_hdl_path_slice("top.DUT.reg2",   0, 32);
      // reg3_inst.add_hdl_path_slice("top.DUT.reg3",   0, 32);
      // reg4_inst.add_hdl_path_slice("top.DUT.reg4",   0, 32);

