
package my_reg_sequences_pkg;


  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import my_sequence_item_pkg::*;
  import my_ral_pkg::*;
  import apb_reg_block_pkg::*;

  // -----------------------------------------------------------------------
  //  ctrl_reg_seq  -  Exercises CNTRL register (0x00)
  // -----------------------------------------------------------------------
  class ctrl_reg_seq extends uvm_reg_sequence;
    `uvm_object_utils(ctrl_reg_seq)

    apb_reg_block reg_block;

    function new(string name = "ctrl_reg_seq");
      super.new(name);
    endfunction

    task body();
      uvm_status_e   status;
      uvm_reg_data_t rd_data;
      uvm_reg_data_t wr_data;

      `uvm_info("CTRL_SEQ"," ---------- CTRL Register Sequence  STARTED ---------- ", UVM_LOW)


      // ------------------------------------------------------------------
      // 1. RESET state inspection
      // ------------------------------------------------------------------
      `uvm_info("CTRL_SEQ", " \n ------[1] Reset State Check -------------------", UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (reset): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Desired  Value (reset): 0x%0h",reg_block.CNTRL.get()), UVM_LOW)


      // ------------------------------------------------------------------
      // 2. FRONTDOOR WRITE  (write via bus through driver)
      // ------------------------------------------------------------------
      wr_data = 32'h0000_000F;   // All 4 ctrl bits HIGH
      `uvm_info("CTRL_SEQ",
        $sformatf(" \n ------[2] Frontdoor WRITE  0x%0h -------------------", wr_data), UVM_LOW)
      reg_block.CNTRL.write(status, wr_data, UVM_FRONTDOOR, null, this);
      `uvm_info("CTRL_SEQ", $sformatf("  Write Status         : %s", status.name()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (post-write): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Desired  Value (post-write): 0x%0h",reg_block.CNTRL.get()), UVM_LOW)
      reg_block.CNTRL.sample_cg(reg_block.CNTRL.get_mirrored_value());


      // ------------------------------------------------------------------
      // 3. FRONTDOOR READ  (read via bus through driver)
      // ------------------------------------------------------------------
      `uvm_info("CTRL_SEQ", " \n ------[3] Frontdoor READ -------------------", UVM_LOW)
      reg_block.CNTRL.read(status, rd_data, UVM_FRONTDOOR, null, this);
      `uvm_info("CTRL_SEQ", $sformatf("  Read Status          : %s", status.name()), UVM_LOW)
      `uvm_info("CTRL_SEQ", $sformatf("  Read Data (DUT)      : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("CTRL_SEQ", $sformatf("  Mirrored Value (post-read) : 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)
      reg_block.CNTRL.sample_cg(rd_data);


      // ------------------------------------------------------------------
      // 4. SET desired value  (model-only, no bus activity)
      // ------------------------------------------------------------------
      wr_data = 32'h0000_0005;   // CTRL0 + CTRL2
      `uvm_info("CTRL_SEQ",$sformatf("\n ------ [4] SET desired = 0x%0h (no bus) ------------------", wr_data), UVM_LOW)
      reg_block.CNTRL.set(wr_data);
      `uvm_info("CTRL_SEQ",$sformatf("  Desired  Value (after set): 0x%0h",reg_block.CNTRL.get()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (still old): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)

      // ------------------------------------------------------------------
      // 5. UPDATE  (push desired value to DUT via frontdoor)
      // ------------------------------------------------------------------
      `uvm_info("CTRL_SEQ", "\n ------ [5] UPDATE (push desired → DUT) ------------------", UVM_LOW)
      reg_block.CNTRL.update(status, UVM_FRONTDOOR, null, this);
      `uvm_info("CTRL_SEQ", $sformatf("  Update Status        : %s", status.name()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Desired  Value (post-update): 0x%0h",reg_block.CNTRL.get()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (post-update): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)
      reg_block.CNTRL.sample_cg(reg_block.CNTRL.get_mirrored_value());

      // ------------------------------------------------------------------
      // 6. MIRROR  (read DUT, compare with model, update mirror)
      // ------------------------------------------------------------------
      `uvm_info("CTRL_SEQ", "\n ------ [6] MIRROR (read DUT & update model) ------------------", UVM_LOW)
      reg_block.CNTRL.mirror(status, UVM_CHECK, UVM_FRONTDOOR, null, this);
      `uvm_info("CTRL_SEQ", $sformatf("  Mirror Status        : %s", status.name()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (post-mirror): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)

      // ------------------------------------------------------------------
      // 7. BACKDOOR WRITE  (write directly to DUT HDL path, bypass bus)
      // ------------------------------------------------------------------
      wr_data = 32'h0000_000A;   // CTRL1 + CTRL3
      `uvm_info("CTRL_SEQ", $sformatf("\n ------ [7] Backdoor WRITE  0x%0h ------------------", wr_data), UVM_LOW)
      reg_block.CNTRL.write(status, wr_data, UVM_BACKDOOR, null, this);
      `uvm_info("CTRL_SEQ", $sformatf("  Backdoor Write Status: %s", status.name()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (post-bd-write): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)
      reg_block.CNTRL.sample_cg(reg_block.CNTRL.get_mirrored_value());

      // ------------------------------------------------------------------
      // 8. BACKDOOR READ  (peek directly from DUT HDL path)
      // ------------------------------------------------------------------
      `uvm_info("CTRL_SEQ", "\n ------  [8] Backdoor READ (peek) ------------------", UVM_LOW)
      reg_block.CNTRL.read(status, rd_data, UVM_BACKDOOR, null, this);
      `uvm_info("CTRL_SEQ", $sformatf("  Backdoor Read Status : %s", status.name()), UVM_LOW)
      `uvm_info("CTRL_SEQ", $sformatf("  Backdoor Read Data   : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (post-bd-read): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)
      reg_block.CNTRL.sample_cg(rd_data);

      // ------------------------------------------------------------------
      // 9. POKE  (backdoor write, alias for write(UVM_BACKDOOR))
      // ------------------------------------------------------------------
      wr_data = 32'h0000_0003;   // CTRL0 + CTRL1
      `uvm_info("CTRL_SEQ",$sformatf("\n ------ [9] POKE  0x%0h (backdoor write alias) ------------------", wr_data), UVM_LOW)
      reg_block.CNTRL.poke(status, wr_data, "", null, this);
      `uvm_info("CTRL_SEQ", $sformatf("  Poke Status          : %s", status.name()), UVM_LOW)

      // ------------------------------------------------------------------
      // 10. PEEK  (backdoor read, alias for read(UVM_BACKDOOR))
      // ------------------------------------------------------------------
      `uvm_info("CTRL_SEQ", "\n ------ [10] PEEK (backdoor read alias) ------------------", UVM_LOW)
      reg_block.CNTRL.peek(status, rd_data, "", null, this);
      `uvm_info("CTRL_SEQ", $sformatf("  Peek Status          : %s", status.name()), UVM_LOW)
      `uvm_info("CTRL_SEQ", $sformatf("  Peek Data (DUT raw)  : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (post-peek)   : 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)
      reg_block.CNTRL.sample_cg(rd_data);

      // ------------------------------------------------------------------
      // 11. PREDICT  (manually force the mirror value without bus access)
      // ------------------------------------------------------------------
      `uvm_info("CTRL_SEQ","\n ------ [11] PREDICT mirror = 0x0 (manual force) ------", UVM_LOW)
      void'(reg_block.CNTRL.predict(32'h0));
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (post-predict): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)

      // ------------------------------------------------------------------
      // 12. RESET  (reset the model mirror+desired to hardware reset val)
      // ------------------------------------------------------------------
      `uvm_info("CTRL_SEQ", "\n ------ [12] RESET register model -----------------------", UVM_LOW)
      reg_block.CNTRL.reset();
      `uvm_info("CTRL_SEQ",$sformatf("  Mirrored Value (post-reset): 0x%0h",reg_block.CNTRL.get_mirrored_value()), UVM_LOW)
      `uvm_info("CTRL_SEQ",$sformatf("  Desired  Value (post-reset): 0x%0h",reg_block.CNTRL.get()), UVM_LOW)


      `uvm_info("CTRL_SEQ","------------- CTRL Register Sequence  DONE ------------- ", UVM_LOW)

    endtask : body

  endclass : ctrl_reg_seq





/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////[reg1_reg_seq  —  Exercises REG1 register (0x04)]///////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////


  class reg1_reg_seq extends uvm_reg_sequence;
    `uvm_object_utils(reg1_reg_seq)

    apb_reg_block reg_block;

    function new(string name = "reg1_reg_seq");
      super.new(name);
    endfunction

    task body();
      uvm_status_e   status;
      uvm_reg_data_t rd_data;
      uvm_reg_data_t wr_data;

      `uvm_info("REG1_SEQ","------------- REG1 Register Sequence  STARTED ------------- ", UVM_LOW)


      // 1. Reset state
      `uvm_info("REG1_SEQ", "\n ------  [1] Reset State Check ------------------", UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (reset): 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Desired  Value (reset): 0x%0h",reg_block.REG1.get()), UVM_LOW)

      // 2. Frontdoor Write
      wr_data = 32'hDEAD_BEEF;
      `uvm_info("REG1_SEQ",$sformatf("\n ------ [2] Frontdoor WRITE  0x%0h -----------------------", wr_data), UVM_LOW)
      reg_block.REG1.write(status, wr_data, UVM_FRONTDOOR, null, this);
      `uvm_info("REG1_SEQ", $sformatf("  Write Status          : %s", status.name()), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (post-write): 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Desired  Value (post-write): 0x%0h",reg_block.REG1.get()), UVM_LOW)
      reg_block.REG1.sample_cg(reg_block.REG1.get_mirrored_value());

      // 3. Frontdoor Read
      `uvm_info("REG1_SEQ", "\n ------ [3] Frontdoor READ ------------------", UVM_LOW)
      reg_block.REG1.read(status, rd_data, UVM_FRONTDOOR, null, this);
      `uvm_info("REG1_SEQ", $sformatf("  Read Status           : %s", status.name()), UVM_LOW)
      `uvm_info("REG1_SEQ", $sformatf("  Read Data  (DUT)      : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (post-read) : 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)
      reg_block.REG1.sample_cg(rd_data);

      // 4. SET + UPDATE
      wr_data = 32'hCAFE_BABE;
      `uvm_info("REG1_SEQ",
        $sformatf("\n ------ [4] SET 0x%0h + UPDATE ------------------", wr_data), UVM_LOW)
      reg_block.REG1.set(wr_data);
      `uvm_info("REG1_SEQ",$sformatf("  Desired  Value (after set) : 0x%0h",reg_block.REG1.get()), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (before upd): 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)
      reg_block.REG1.update(status, UVM_FRONTDOOR, null, this);
      `uvm_info("REG1_SEQ", $sformatf("  Update Status         : %s", status.name()), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (post-upd)  : 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)
      reg_block.REG1.sample_cg(reg_block.REG1.get_mirrored_value());

      // 5. Mirror
      `uvm_info("REG1_SEQ", "\n ------ [5] MIRROR ------------------", UVM_LOW)
      reg_block.REG1.mirror(status, UVM_CHECK, UVM_FRONTDOOR, null, this);
      `uvm_info("REG1_SEQ", $sformatf("  Mirror Status         : %s", status.name()), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (post-mirror): 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)

      // 6. POKE (backdoor write alias)
      wr_data = 32'h1234_5678;
      `uvm_info("REG1_SEQ",$sformatf("\n ------ [6] POKE 0x%0h ------------------", wr_data), UVM_LOW)
      reg_block.REG1.poke(status, wr_data, "", null, this);
      `uvm_info("REG1_SEQ", $sformatf("  Poke Status           : %s", status.name()), UVM_LOW)

      // 7. PEEK (backdoor read alias)
      `uvm_info("REG1_SEQ", "\n ------ [7] PEEK ------------------", UVM_LOW)
      reg_block.REG1.peek(status, rd_data, "", null, this);
      `uvm_info("REG1_SEQ", $sformatf("  Peek Status           : %s", status.name()), UVM_LOW)
      `uvm_info("REG1_SEQ", $sformatf("  Peek Data  (DUT raw)  : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (post-peek) : 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)
      reg_block.REG1.sample_cg(rd_data);

      // 8. PREDICT
      `uvm_info("REG1_SEQ","\n ------ [8] PREDICT mirror = 0xABCDEF01 ------------------", UVM_LOW)
      void'(reg_block.REG1.predict(32'hABCD_EF01));
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (post-predict): 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)

      // 9. RESET model
      `uvm_info("REG1_SEQ", "\n ------ [9] RESET register model -----------------------------", UVM_LOW)
      reg_block.REG1.reset();
      `uvm_info("REG1_SEQ",$sformatf("  Mirrored Value (post-reset): 0x%0h",reg_block.REG1.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG1_SEQ",$sformatf("  Desired  Value (post-reset): 0x%0h",reg_block.REG1.get()), UVM_LOW)

      `uvm_info("REG1_SEQ","------------- REG1 Register Sequence  [DONE] -----------------", UVM_LOW)

    endtask : body

  endclass : reg1_reg_seq





/////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////// [ reg2_reg_seq  —  Exercises REG2 register (0x08)] ///////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////





  //  

  class reg2_reg_seq extends uvm_reg_sequence;
    `uvm_object_utils(reg2_reg_seq)

    apb_reg_block reg_block;

    function new(string name = "reg2_reg_seq");
      super.new(name);
    endfunction

    task body();
      uvm_status_e   status;
      uvm_reg_data_t rd_data;
      uvm_reg_data_t wr_data;

      `uvm_info("REG2_SEQ","------------- REG2 Register Sequence  STARTED ------------- ", UVM_LOW)


      // 1. Reset state
      `uvm_info("REG2_SEQ", "\n ----  [1] Reset State Check ------------------", UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (reset): 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Desired  Value (reset): 0x%0h",reg_block.REG2.get()), UVM_LOW)

      // 2. Frontdoor Write
      wr_data = 32'hA5A5_A5A5;
      `uvm_info("REG2_SEQ",$sformatf("\n ----  [2] Frontdoor WRITE  0x%0h ------------------", wr_data), UVM_LOW)
      reg_block.REG2.write(status, wr_data, UVM_FRONTDOOR, null, this);
      `uvm_info("REG2_SEQ", $sformatf("  Write Status          : %s", status.name()), UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (post-write): 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Desired  Value (post-write): 0x%0h",reg_block.REG2.get()), UVM_LOW)
      reg_block.REG2.sample_cg(reg_block.REG2.get_mirrored_value());

      // 3. Frontdoor Read
      `uvm_info("REG2_SEQ", "\n ----  [3] Frontdoor READ ------------------", UVM_LOW)
      reg_block.REG2.read(status, rd_data, UVM_FRONTDOOR, null, this);
      `uvm_info("REG2_SEQ", $sformatf("  Read Status           : %s", status.name()), UVM_LOW)
      `uvm_info("REG2_SEQ", $sformatf("  Read Data  (DUT)      : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("REG2_SEQ", $sformatf("  Mirrored Value (post-read) : 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)
      reg_block.REG2.sample_cg(rd_data);

      // 4. SET + UPDATE
      wr_data = 32'h5A5A_5A5A;
      `uvm_info("REG2_SEQ",
        $sformatf("\n ----  [4] SET 0x%0h + UPDATE ------------------", wr_data), UVM_LOW)
      reg_block.REG2.set(wr_data);
      `uvm_info("REG2_SEQ",$sformatf("  Desired  Value (after set) : 0x%0h",reg_block.REG2.get()), UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (before upd): 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)
      reg_block.REG2.update(status, UVM_FRONTDOOR, null, this);
      `uvm_info("REG2_SEQ", $sformatf("  Update Status         : %s", status.name()), UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (post-upd)  : 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)
      reg_block.REG2.sample_cg(reg_block.REG2.get_mirrored_value());

      // 5. Mirror
      `uvm_info("REG2_SEQ", "\n ----  [5] MIRROR ------------------", UVM_LOW)
      reg_block.REG2.mirror(status, UVM_CHECK, UVM_FRONTDOOR, null, this);
      `uvm_info("REG2_SEQ", $sformatf("  Mirror Status         : %s", status.name()), UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (post-mirror): 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)

      // 6. Backdoor write (UVM_BACKDOOR path)
      wr_data = 32'hBEEF_CAFE;
      `uvm_info("REG2_SEQ",$sformatf("\n ----  [6] Backdoor WRITE  0x%0h ------------------", wr_data), UVM_LOW)
      reg_block.REG2.write(status, wr_data, UVM_BACKDOOR, null, this);
      `uvm_info("REG2_SEQ", $sformatf("  Backdoor Write Status : %s", status.name()), UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (post-bd-wr): 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)
      reg_block.REG2.sample_cg(reg_block.REG2.get_mirrored_value());

      // 7. Backdoor read (UVM_BACKDOOR path)
      `uvm_info("REG2_SEQ", "\n ----  [7] Backdoor READ ------------------", UVM_LOW)
      reg_block.REG2.read(status, rd_data, UVM_BACKDOOR, null, this);
      `uvm_info("REG2_SEQ", $sformatf("  Backdoor Read Status  : %s", status.name()), UVM_LOW)
      `uvm_info("REG2_SEQ", $sformatf("  Backdoor Read Data    : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (post-bd-rd): 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)
      reg_block.REG2.sample_cg(rd_data);

      // 8. PREDICT
      `uvm_info("REG2_SEQ","\n ----  [8] PREDICT mirror = 0x11223344 ------------------", UVM_LOW)
      void'(reg_block.REG2.predict(32'h1122_3344));
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (post-predict): 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)

      // 9. Reset
      `uvm_info("REG2_SEQ", "\n ----  [9] RESET register model ------------------", UVM_LOW)
      reg_block.REG2.reset();
      `uvm_info("REG2_SEQ",$sformatf("  Mirrored Value (post-reset): 0x%0h",reg_block.REG2.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG2_SEQ", $sformatf("  Desired  Value (post-reset): 0x%0h", reg_block.REG2.get()), UVM_LOW)
      `uvm_info("REG2_SEQ","[DONE] :: REG2 Register Sequence", UVM_LOW)

    endtask : body

  endclass : reg2_reg_seq






/////////////////////////////////////////////////////////////////////////////////////////////////////
/////// [ reg3_reg_seq  —  Exercises REG3 register (0x0C) ] /////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////


  class reg3_reg_seq extends uvm_reg_sequence;
    `uvm_object_utils(reg3_reg_seq)

    apb_reg_block reg_block;

    function new(string name = "reg3_reg_seq");
      super.new(name);
    endfunction

    task body();
      uvm_status_e   status;
      uvm_reg_data_t rd_data;
      uvm_reg_data_t wr_data;

      `uvm_info("REG3_SEQ","------------- REG3 Register Sequence  STARTED ------------- ", UVM_LOW)


      // 1. Reset state
      `uvm_info("REG3_SEQ", "\n ----  [1] Reset State Check -------------------", UVM_LOW)
      `uvm_info("REG3_SEQ",$sformatf("  Mirrored Value (reset): 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG3_SEQ",$sformatf("  Desired  Value (reset): 0x%0h",reg_block.REG3.get()), UVM_LOW)

      // 2. Frontdoor Write
      wr_data = 32'h55AA_55AA;
      `uvm_info("REG3_SEQ",$sformatf("\n ----   [2] Frontdoor WRITE  0x%0h -----------------------", wr_data), UVM_LOW)
      reg_block.REG3.write(status, wr_data, UVM_FRONTDOOR, null, this);
      `uvm_info("REG3_SEQ", $sformatf("  Write Status          : %s", status.name()), UVM_LOW)
      `uvm_info("REG3_SEQ", $sformatf("  Mirrored Value (post-write): 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG3_SEQ", $sformatf("  Desired  Value (post-write): 0x%0h",reg_block.REG3.get()), UVM_LOW)
      reg_block.REG3.sample_cg(reg_block.REG3.get_mirrored_value());

      // 3. Frontdoor Read
      `uvm_info("REG3_SEQ", "\n ----  [3] Frontdoor READ ------------------", UVM_LOW)
      reg_block.REG3.read(status, rd_data, UVM_FRONTDOOR, null, this);
      `uvm_info("REG3_SEQ", $sformatf("  Read Status           : %s", status.name()), UVM_LOW)
      `uvm_info("REG3_SEQ", $sformatf("  Read Data  (DUT)      : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("REG3_SEQ", $sformatf("  Mirrored Value (post-read) : 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)
      reg_block.REG3.sample_cg(rd_data);

      // 4. SET + UPDATE
      wr_data = 32'hAA55_AA55;
      `uvm_info("REG3_SEQ",$sformatf("\n ----  [4] SET 0x%0h + UPDATE -------------------", wr_data), UVM_LOW)
      reg_block.REG3.set(wr_data);
      `uvm_info("REG3_SEQ",$sformatf("  Desired  Value (after set) : 0x%0h",reg_block.REG3.get()), UVM_LOW)
      `uvm_info("REG3_SEQ",$sformatf("  Mirrored Value (before upd): 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)
      reg_block.REG3.update(status, UVM_FRONTDOOR, null, this);
      `uvm_info("REG3_SEQ", $sformatf("  Update Status         : %s", status.name()), UVM_LOW)
      `uvm_info("REG3_SEQ", $sformatf("  Mirrored Value (post-upd)  : 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)
      reg_block.REG3.sample_cg(reg_block.REG3.get_mirrored_value());

      // 5. Mirror
      `uvm_info("REG3_SEQ", "\n ----  [5] MIRROR ------------------", UVM_LOW)
      reg_block.REG3.mirror(status, UVM_CHECK, UVM_FRONTDOOR, null, this);
      `uvm_info("REG3_SEQ", $sformatf("  Mirror Status         : %s", status.name()), UVM_LOW)
      `uvm_info("REG3_SEQ", $sformatf("  Mirrored Value (post-mirror): 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)

      // 6. POKE
      wr_data = 32'hFACE_FACE;
      `uvm_info("REG3_SEQ",$sformatf("\n ----  [6] POKE  0x%0h ------------------------", wr_data), UVM_LOW)
      reg_block.REG3.poke(status, wr_data, "", null, this);
      `uvm_info("REG3_SEQ", $sformatf("  Poke Status           : %s", status.name()), UVM_LOW)

      // 7. PEEK
      `uvm_info("REG3_SEQ", "\n ----  [7] PEEK ------------------", UVM_LOW)
      reg_block.REG3.peek(status, rd_data, "", null, this);
      `uvm_info("REG3_SEQ", $sformatf("  Peek Status           : %s", status.name()), UVM_LOW)
      `uvm_info("REG3_SEQ", $sformatf("  Peek Data  (DUT raw)  : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("REG3_SEQ",$sformatf("  Mirrored Value (post-peek) : 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)
      reg_block.REG3.sample_cg(rd_data);

      // 8. PREDICT
      `uvm_info("REG3_SEQ","\n ----  [8] PREDICT mirror = 0xDEADDEAD ------------------", UVM_LOW)
      void'(reg_block.REG3.predict(32'hDEAD_DEAD));
      `uvm_info("REG3_SEQ",$sformatf("  Mirrored Value (post-predict): 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)

      // 9. Reset
      `uvm_info("REG3_SEQ", "\n ----  [9] RESET register model ------------------", UVM_LOW)
      reg_block.REG3.reset();
      `uvm_info("REG3_SEQ",$sformatf("  Mirrored Value (post-reset): 0x%0h",reg_block.REG3.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG3_SEQ",$sformatf("  Desired  Value (post-reset): 0x%0h",reg_block.REG3.get()), UVM_LOW)
      `uvm_info("REG3_SEQ","[DONE] :: REG3 Register Sequence", UVM_LOW)
 
    endtask : body

  endclass : reg3_reg_seq






/////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////// [ reg4_reg_seq  —  Exercises REG4 register (0x10) ] ////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////



  class reg4_reg_seq extends uvm_reg_sequence;
    `uvm_object_utils(reg4_reg_seq)

    apb_reg_block reg_block;

    function new(string name = "reg4_reg_seq");
      super.new(name);
    endfunction

    task body();
      uvm_status_e   status;
      uvm_reg_data_t rd_data;
      uvm_reg_data_t wr_data;


      `uvm_info("REG4_SEQ","------------- REG4 Register Sequence  STARTED ------------- ", UVM_LOW)


      // 1. Reset state
      `uvm_info("REG4_SEQ", "\n ----  [1] Reset State Check ------------------", UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (reset): 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Desired  Value (reset): 0x%0h",reg_block.REG4.get()), UVM_LOW)

      // 2. Frontdoor Write
      wr_data = 32'hFFFF_FFFF;
      `uvm_info("REG4_SEQ",$sformatf("\n ---- [2] Frontdoor WRITE  0x%0h ----------------------", wr_data), UVM_LOW)
      reg_block.REG4.write(status, wr_data, UVM_FRONTDOOR, null, this);
      `uvm_info("REG4_SEQ", $sformatf("  Write Status          : %s", status.name()), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (post-write): 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Desired  Value (post-write): 0x%0h",reg_block.REG4.get()), UVM_LOW)
      reg_block.REG4.sample_cg(reg_block.REG4.get_mirrored_value());

      // 3. Frontdoor Read
      `uvm_info("REG4_SEQ", "\n ---- [3] Frontdoor READ ------------------", UVM_LOW)
      reg_block.REG4.read(status, rd_data, UVM_FRONTDOOR, null, this);
      `uvm_info("REG4_SEQ", $sformatf("  Read Status           : %s", status.name()), UVM_LOW)
      `uvm_info("REG4_SEQ", $sformatf("  Read Data  (DUT)      : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (post-read) : 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)
      reg_block.REG4.sample_cg(rd_data);

      // 4. SET + UPDATE
      wr_data = 32'h00FF_00FF;
      `uvm_info("REG4_SEQ",$sformatf("\n ---- [4] SET 0x%0h + UPDATE ------------------", wr_data), UVM_LOW)
      reg_block.REG4.set(wr_data);
      `uvm_info("REG4_SEQ",$sformatf("  Desired  Value (after set) : 0x%0h",reg_block.REG4.get()), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (before upd): 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)

      reg_block.REG4.update(status, UVM_FRONTDOOR, null, this);
      `uvm_info("REG4_SEQ", $sformatf("  Update Status         : %s", status.name()), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (post-upd)  : 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)
      reg_block.REG4.sample_cg(reg_block.REG4.get_mirrored_value());

      // 5. Mirror
      `uvm_info("REG4_SEQ", "\n ---- [5] MIRROR ------------------", UVM_LOW)
      reg_block.REG4.mirror(status, UVM_CHECK, UVM_FRONTDOOR, null, this);
      `uvm_info("REG4_SEQ", $sformatf("  Mirror Status         : %s", status.name()), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (post-mirror): 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)

      // 6. POKE
      wr_data = 32'h0000_FEED;
      `uvm_info("REG4_SEQ",$sformatf("\n ---- [6] POKE  0x%0h ------------------", wr_data), UVM_LOW)
      reg_block.REG4.poke(status, wr_data, "", null, this);
      `uvm_info("REG4_SEQ", $sformatf("  Poke Status           : %s", status.name()), UVM_LOW)

      // 7. PEEK
      `uvm_info("REG4_SEQ", "\n ---- [7] PEEK ------------------", UVM_LOW)
      reg_block.REG4.peek(status, rd_data, "", null, this);
      `uvm_info("REG4_SEQ", $sformatf("  Peek Status           : %s", status.name()), UVM_LOW)
      `uvm_info("REG4_SEQ", $sformatf("  Peek Data  (DUT raw)  : 0x%0h", rd_data), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (post-peek) : 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)
      reg_block.REG4.sample_cg(rd_data);

      // 8. PREDICT
      `uvm_info("REG4_SEQ","\n ---- [8] PREDICT mirror = 0xBEBEBEBE ------------------", UVM_LOW)
      void'(reg_block.REG4.predict(32'hBEBE_BEBE));
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (post-predict): 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)

      // 9. Reset
      `uvm_info("REG4_SEQ", "\n ---- [9] RESET register model ------------------\n ", UVM_LOW)
      reg_block.REG4.reset();
      `uvm_info("REG4_SEQ",$sformatf("  Mirrored Value (post-reset): 0x%0h",reg_block.REG4.get_mirrored_value()), UVM_LOW)
      `uvm_info("REG4_SEQ",$sformatf("  Desired  Value (post-reset): 0x%0h",reg_block.REG4.get()), UVM_LOW)
      `uvm_info("REG4_SEQ","[DONE] :: REG4 Register Sequence ", UVM_LOW)

    endtask : body

  endclass : reg4_reg_seq

endpackage : my_reg_sequences_pkg