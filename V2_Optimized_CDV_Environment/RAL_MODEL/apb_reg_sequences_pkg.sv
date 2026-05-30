/*
when the sequence is started from somewhere that does NOT have direct access to reg_block, for example a virtual sequence started deep inside a component that never touched the reg_block.
Then the sequence would have no choice but to pull it from config_db itself.
If the test starts it -> test has the handle -> direct assignment
If some component deep in the hierarchy starts it -> that component may not have the handle → config_db::get in body()
*/

package apb_reg_sequences_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import apb_sequence_item_pkg::*;
  import apb_reg_block_pkg::*; // to interact with the whole memory map
  import apb_regs_pkg::*;      // 3shan will practice kol reg 


  class base_reg_seq extends uvm_sequence;
    `uvm_object_utils(base_reg_seq)

    // --- Shared Variables ---
    top_reg_block  reg_block;    // direct assignment from test before start()
    uvm_status_e   status;
    uvm_reg_data_t rd_data;
    uvm_reg_data_t wr_data;
    uvm_reg_data_t rst_val;
    bit            has_rst;

    function new(string name = "base_reg_seq");
      super.new(name);
    endfunction

    //--------------------------------------------
    // ----- Generic Flow for Every Register -----
    //--------------------------------------------
    
    // Task Implement all APIs :)
    extern virtual task test_any_register(string tag, string reg_name, uvm_reg target_reg, string path);

    // Reg State Printer ::
    extern protected task print_reg_state( // na msh ha overwrite it na ha pass bs args
      string          tag,
      string          api_used,          // "WRITE" , "READ" , "POKE"
      string          phase,             // "before", "post-API"
      uvm_reg         target_reg,
      string          path,
      bit             has_status = 0,
      uvm_status_e    op_status  = UVM_IS_OK
    );

    extern function void print_seq_start(string tag, string reg_name);
    
    extern task print_seq_done(string tag, string reg_name, uvm_reg target_reg);
    
    // virtual task body();
    //   // if (!uvm_config_db#(top_reg_block)::get(null, get_full_name(), "reg_block", reg_block)) begin
    //   //   `uvm_fatal("BASE_REG_SEQ", "Failed to get 'reg_block' from uvm_config_db! | CHECK : setting in the test before start()")
    //   // 
    //   // Test already has it — just hand it over directly ::
    //   // seq_ctrl.reg_block = reg_block;
    //   // seq_ctrl.start(env.agent.seqr);
    // endtask


  endclass : base_reg_seq


  /////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////[ CONTROL REG ] ////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////

  class CNTRL_reg_seq extends base_reg_seq;
    `uvm_object_utils(CNTRL_reg_seq)

    function new(string name = "CNTRL_reg_seq");
      super.new(name); 
    endfunction

    virtual task body();
      // super.body(); // fetch reg_block from config_db
      test_any_register("CTRL_SEQ", "CNTRL_REG", reg_block.cntrl_inst, "top.DUT.cntrl");
    endtask
  endclass


  /////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////[ REG1 ] ///////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////

  class reg1_seq extends base_reg_seq;
    `uvm_object_utils(reg1_seq)

    function new(string name = "reg1_seq");
      super.new(name); 
    endfunction

    virtual task body();
      // super.body(); // fetch reg_block from config_db
      test_any_register("REG1_SEQ", "REG1_REG", reg_block.reg1_inst, "top.DUT.reg1");
    endtask
  endclass


  /////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////[ REG2 ] ///////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////

  class reg2_seq extends base_reg_seq;
    `uvm_object_utils(reg2_seq)

    function new(string name = "reg2_seq");
      super.new(name); 
    endfunction

    virtual task body();
      // super.body(); // fetch reg_block from config_db
      test_any_register("REG2_SEQ", "REG2_REG", reg_block.reg2_inst, "top.DUT.reg2");
    endtask
  endclass


  /////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////[ REG3 ] ///////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////

  class reg3_seq extends base_reg_seq;
    `uvm_object_utils(reg3_seq)

    function new(string name = "reg3_seq");
      super.new(name); 
    endfunction

    virtual task body();
      // super.body(); // fetch reg_block from config_db
      test_any_register("REG3_SEQ", "REG3_REG", reg_block.reg3_inst, "top.DUT.reg3");
    endtask
  endclass


  /////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////[ REG4 ] ///////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////

  class reg4_seq extends base_reg_seq;
    `uvm_object_utils(reg4_seq)

    function new(string name = "reg4_seq");
      super.new(name); 
    endfunction

    virtual task body();
      // super.body(); // fetch reg_block from config_db
      test_any_register("REG4_SEQ", "REG4_REG", reg_block.reg4_inst, "top.DUT.reg4");
    endtask
  endclass



  /////////////////////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////[ EXTERN FUNCTION] /////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////////////


  function void base_reg_seq::print_seq_start(string tag, string reg_name);
    `uvm_info(tag,$sformatf(" ---------- %0s Register Sequence  STARTED ---------- ", reg_name),UVM_LOW)
  endfunction



//////////////////
/////////////////


  task base_reg_seq::print_reg_state(
    string          tag,
    string          api_used,
    string          phase,
    uvm_reg         target_reg,
    string          path,
    bit             has_status = 0,        // Defaults 3shan lw msh mhtagahom msh ha pass it wmytl3sh error
    uvm_status_e    op_status  = UVM_IS_OK
    
  );

    uvm_reg_data_t  dut_val;
    //uvm_status_e    dummy_st;
    uvm_reg_data_t mirrored_value;
    uvm_reg_data_t Desired_value;
    uvm_reg_data_t DUT_value;

    Desired_value  = target_reg.get();
    mirrored_value = target_reg.get_mirrored_value();
    #1;
    if (!uvm_hdl_read(path, DUT_value))
      `uvm_error(tag, $sformatf("uvm_hdl_read from '%s' failed — check hdl_path", path));
    dut_val = DUT_value;
    // target_reg.peek(dummy_st, dut_val);
    // if (dummy_st != UVM_IS_OK) begin
    //   `uvm_warning(tag, "Initial peek failed — DUT_value tracking unreliable (check hdl_path)");
    // end

    // -- operation banner ( est5dmt $display so it appears as a separator line) --
    $display("\n #------------------- [%0s] (%0s) -------------------", api_used, phase);
 
    // -- Desired / Mirrored / DUT  (column-aligned, colon at position 32) --
    `uvm_info(tag, $sformatf("   %-32s : 0x%0h",$sformatf("Desired  Value (%0s)", phase),Desired_value),UVM_LOW)
    `uvm_info(tag, $sformatf("   %-32s : 0x%0h",$sformatf("Mirrored Value (%0s)", phase),mirrored_value),UVM_LOW)
    `uvm_info(tag, $sformatf("   %-32s : 0x%0h",$sformatf("DUT Reg  Value (%0s)", phase),dut_val),UVM_LOW)
 
    // -- Status line (optional) --
    if (has_status) begin
      `uvm_info(tag, $sformatf("   %-32s : %0s",$sformatf("%0s Status", api_used),op_status.name()),UVM_LOW)
    end

  endtask



//////////////////
/////////////////


  task base_reg_seq::print_seq_done(string tag, string reg_name, uvm_reg target_reg);
    uvm_reg_data_t dut_val;
    uvm_status_e   dummy_st;

    target_reg.peek(dummy_st, dut_val);
    if (dummy_st != UVM_IS_OK) begin
      `uvm_warning(tag, "Initial peek failed — DUT_value tracking unreliable (check hdl_path)");
    end

    `uvm_info(tag, $sformatf("\n ----------------- [ %0s FINAL STATE ] ---------------------------",reg_name), UVM_LOW)
    `uvm_info(tag, $sformatf("   %-32s : 0x%0h", "Desired Value (final)",  target_reg.get()), UVM_LOW)
    `uvm_info(tag, $sformatf("   %-32s : 0x%0h", "Mirrored Value (final)", target_reg.get_mirrored_value()), UVM_LOW)
    `uvm_info(tag, $sformatf("   %-32s : 0x%0h", "DUT Reg Value (final)",  dut_val), UVM_LOW)
    `uvm_info(tag, $sformatf("----------------- [ %0s SEQUENCES DONEEEEEEEE ] --------------------------- \n ", reg_name), UVM_LOW)
    

  endtask



//////////////////
/////////////////





  task base_reg_seq::test_any_register(string tag, string reg_name, uvm_reg target_reg, string path);
    uvm_reg_data_t  orig_rst_val;
    uvm_status_e    dummy_st; // Used for silent backdoor peeks
    bit             has_rst;

    print_seq_start(tag, reg_name);

    // -------------------------------------------------------------------------------------- 
    // 1. PRE-TRANSACTION (SET) | (model only — no bus, no coverage)

    $display("\n # ------ [1] SET desired (no bus) -------------------");
      print_reg_state(tag, "SET", "Before-Set (DEAD_BEEF)", target_reg, path);
      target_reg.set(32'hDEAD_BEEF);
      print_reg_state(tag, "SET", "After-Set (DEAD_BEEF)", target_reg, path);
    // -------------------------------------------------------------------------------------- 
    

    // -------------------------------------------------------------------------------------- 
    // 2. FRONT_DOOR WRITE (RANDOMIZE + WRITE) | coverage auto-fires via UVM sample() hook
    $display("\n # ------ [2] FRONT_DOOR WRITE (RANDOMIZE + WRITE)-------------------");

      if (!target_reg.randomize()) begin
        `uvm_error(tag, "Randomize failed!")      
      end
      else begin
        wr_data = target_reg.get();
        `uvm_info(tag, $sformatf("Randomize PASSED :: 0x%0h", wr_data), UVM_LOW)
      end
        
      print_reg_state(tag, "WRITE", "Before-write", target_reg, path);
      target_reg.write(status, wr_data, UVM_FRONTDOOR, null, this);
      print_reg_state(tag, "WRITE", "After-write", target_reg, path, 1, status);
    // --------------------------------------------------------------------------------------


    // --------------------------------------------------------------------------------------
    // 3. FRONT_DOOR READ | coverage auto-fires
    $display("\n # ------ [3] Frontdoor READ -------------------");
      print_reg_state(tag, "READ", "before", target_reg, path);
      target_reg.read(status, rd_data, UVM_FRONTDOOR, null, this);
      print_reg_state(tag, "READ", "post-read", target_reg, path, 1, status);
    // --------------------------------------------------------------------------------------

    // --------------------------------------------------------------------------------------
    // 4. BACKDOOR WRITE | NO coverage
    $display("\n # ------ [4] Backdoor WRITE -------------------");

      // if (!target_reg.randomize()) begin
      //   `uvm_error(tag, "Randomize failed!")      
      // end
      // else begin
      //   wr_data = target_reg.get();
      //   `uvm_info(tag, $sformatf("Randomize PASSED :: 0x%0h", wr_data), UVM_LOW)
      // end
      wr_data = 'hAAAA_FFFF;

      print_reg_state(tag, "BD_WRITE", "before", target_reg, path);
      target_reg.write(status, wr_data, UVM_BACKDOOR, null, this);
      print_reg_state(tag, "BD_WRITE", "post-bd-write (EXPECTED AAAA_FFFF", target_reg, path, 1, status);
    // --------------------------------------------------------------------------------------

    // --------------------------------------------------------------------------------------
    // 5. BACKDOOR READ | NO coverage
    $display("\n # ------ [5] Backdoor READ -------------------");

      print_reg_state(tag, "BD_READ", "before", target_reg, path);
      target_reg.read(status, rd_data, UVM_BACKDOOR, null, this);
      print_reg_state(tag, "BD_READ", "post-bd-read", target_reg, path, 1, status);
    // --------------------------------------------------------------------------------------


    // --------------------------------------------------------------------------------------
    // 6. POKE | NO coverage
    $display("\n # ------ [6] POKE (backdoor write alias) -------------------");

      if (!target_reg.randomize()) begin
        `uvm_error(tag, "Randomize failed!")      
      end
      else begin
        wr_data = target_reg.get();
        `uvm_info(tag, $sformatf("Randomize PASSED :: 0x%0h", wr_data), UVM_LOW)
      end

      print_reg_state(tag, "POKE", "before", target_reg, path);
      target_reg.poke(status, wr_data, "", null, this);
      print_reg_state(tag, "POKE", "post-poke", target_reg, path, 1, status);
    // --------------------------------------------------------------------------------------
    
    // --------------------------------------------------------------------------------------
    // 7. PEEK  — NO coverage
    $display("\n # ------ [7] PEEK (backdoor read alias) -------------------");

      print_reg_state(tag, "PEEK", "before", target_reg, path);
      target_reg.peek(status, rd_data, "", null, this);
      print_reg_state(tag, "PEEK", "post-peek", target_reg, path, 1, status);
    // --------------------------------------------------------------------------------------

    // --------------------------------------------------------------------------------------
    // 8. Randomize & UPDATE  — coverage auto-fires (frontdoor)
    $display("\n # ------ [8] UPDATE (push desired to DUT) -------------------");

      if (!target_reg.randomize()) begin
        `uvm_error(tag, "Randomize failed!")      
      end
      else begin
        wr_data = target_reg.get();
        `uvm_info(tag, $sformatf("Randomize PASSED :: 0x%0h", wr_data), UVM_LOW)
      end

      print_reg_state(tag, "UPDATE", "before", target_reg, path);
      target_reg.update(status, UVM_FRONTDOOR, null, this);
      print_reg_state(tag, "UPDATE", "post-update", target_reg, path, 1, status);
    // --------------------------------------------------------------------------------------
    

    // ------------------------------------------------------------------ 
    // 9. PREDICT | manual sample() call (no bus, hook won't fire)

    $display("\n # ------ [9] PREDICT -> MIRROR_NO_CHECK -------------------");

      if (!target_reg.randomize()) begin
        `uvm_error(tag, "Randomize failed!")      
      end
      else begin
        wr_data = target_reg.get();
        `uvm_info(tag, $sformatf("Randomize PASSED :: 0x%0h", wr_data), UVM_LOW)
      end

      print_reg_state(tag, "PREDICT", "before", target_reg, path);

      // Force model to W  (DUT untouched — now out of sync)
      void'(target_reg.predict(wr_data, .kind(UVM_PREDICT_DIRECT)));
      target_reg.sample_values();  // manual coverage (no bus hook)

      print_reg_state(tag, "PREDICT", "post-predict (model=W, DUT=old)", target_reg, path);

      // Read DUT and silently update model — no mismatch error
      target_reg.mirror(status, UVM_NO_CHECK, UVM_FRONTDOOR, null, this);

      print_reg_state(tag, "MIRROR_NO_CHECK", "post-mirror (model re-synced to DUT)", target_reg, path, 1, status);

    // ------------------------------------------------------------------ 

    // ------------------------------------------------------------------
    // 10. MIRROR  | coverage auto-fires (frontdoor read + compare)
    $display("\n # ------ [10] UPDATE -> MIRROR_CHECK -------------------");

      if (!target_reg.randomize()) begin
        `uvm_error(tag, "Randomize failed!")
      end
      else begin
        wr_data = target_reg.get();
        `uvm_info(tag, $sformatf("Randomize PASSED :: 0x%0h", wr_data), UVM_LOW)
      end

      print_reg_state(tag, "UPDATE", "before (desired=X, DUT=old)", target_reg, path);

      // Push new desired value X to DUT via frontdoor
      target_reg.update(status, UVM_FRONTDOOR, null, this);

      print_reg_state(tag, "UPDATE", "post-update (model=X, DUT=X)", target_reg, path, 1, status);

      // Read DUT and CHECK — must match mirrored now
      target_reg.mirror(status, UVM_CHECK, UVM_FRONTDOOR, null, this);

      print_reg_state(tag, "MIRROR_CHECK", "post-mirror (expect PASS)", target_reg, path, 1, status);
    // ------------------------------------------------------------------

    // ------------------------------------------------------------------
    // 11. RESET APIs
    // ------------------------------------------------------------------ 
      `uvm_info(tag, "\n ----  [11] RESET register model ------------------", UVM_LOW)
      
      // has_reset
      has_rst = target_reg.has_reset("HARD");
      `uvm_info(tag, $sformatf("   %-32s : %0b  (%0s)", "has_reset(HARD)",has_rst, has_rst ? "reset value IS defined" : "NO reset defined"), UVM_LOW)

      // get_reset  (save original)
      orig_rst_val = target_reg.get_reset("HARD");
      `uvm_info(tag, $sformatf("   %-32s : 0x%0h  <- saved", "get_reset(HARD)", orig_rst_val), UVM_LOW)

      // reset()  
      print_reg_state(tag, "RESET", "before (with original value)", target_reg, path);
        target_reg.reset("HARD");
      print_reg_state(tag, "RESET", "post-reset(original)", target_reg, path);

      // set_reset  
      target_reg.set_reset(32'hDEAD_0000, "HARD");
      `uvm_info(tag, $sformatf("   %-32s : done (reset-override)", "set_reset(DEAD_0000)"), UVM_LOW)

      // get_reset  
      `uvm_info(tag, $sformatf("   %-32s : 0x%0h  (expect DEAD_0000)","get_reset(HARD) (verify override stored)", target_reg.get_reset("HARD")), UVM_LOW)

      // reset()  
      print_reg_state(tag, "RESET", "before (with overridden value)", target_reg, path);
        target_reg.reset("HARD");
      print_reg_state(tag, "RESET", "post-reset(verify overridden)", target_reg, path);

      // restore original
        target_reg.set_reset(orig_rst_val, "HARD");
      `uvm_info(tag, $sformatf("   %-32s : 0x%0h","Restored get_reset(HARD) :: [Original_setted]", target_reg.get_reset("HARD")), UVM_LOW)
        target_reg.reset("HARD");
      print_reg_state(tag, "RESET", "post-reset(restored)", target_reg, path);

      
      // FINAL BANNERS
      print_seq_done(tag, reg_name, target_reg); 

  endtask


//////////////////
/////////////////




endpackage


//---------------------------------- DRAFT ---------------------------------------  
  //-------------------------------------------------------------------
  // takes :: string , string , uvm_reg
  // test_any_register("CTRL_SEQ", "CNTRL", reg_block.CNTRL);
  // test_any_register(string tag, string reg_name, uvm_reg target_reg);
  // test_any_register(get_name(), string reg_name, uvm_reg target_reg);
  //-------------------------------------------------------------------
 

  //---------------------------------------------------------
  //  Printer [1] print_reg_state ::
  //   Output style:
  //   ------- [WRITE] (post-write) -------------------
  //   [TAG]   Desired  Value (post-write)  : 0xf
  //   [TAG]   Mirrored Value (post-write)  : 0xf
  //   [TAG]   DUT Reg  Value (post-write)  : 0xf
  //   [TAG]   WRITE    Status              : UVM_IS_OK 

  // it need ::sequence name , api-used, before/after , uvm_reg target_name, has_status flag, status)
  // print_reg_state(tag, "SET", "before", target_reg);
  // print_reg_state(tag, "WRITE", "before", target_reg);
  // print_reg_state(tag, "WRITE", "post-write", target_reg, 1, status);
  // TASK as it calls peek internally
  //---------------------------------------------------------

  //---------------------------------------------------------
  //  Printer [2] print_seq_start ::
  //  `uvm_info(tag, $sformatf("-----------------  %s Register Sequence  STARTED  ---------------------------", reg_name), UVM_LOW)
  //  Output:
  //   [TAG]  ---------- CNTRL Register Sequence  STARTED ----------
  //   print_seq_start(tag, reg_name);
  //---------------------------------------------------------



  // ------------------------------------------------------------------ 
  //  Printer [3]  print_seq_done :: 
  //  Output: (string tag, string reg_name, uvm_reg target_reg)
  //   [TAG]  ----------------- [ CNTRL FINAL STATE ] ---------------------------
  //   [TAG]   Desired  Value (final)  : 0xVAL -> target_reg.get()
  //   [TAG]   Mirrored Value (final)  : 0xVAL -> get_mirrored_value()
  //   [TAG]   DUT Reg  Value (final)  : 0xVAL -> need to call peek()
  //   [TAG]  ----------------- [ CNTRL SEQUENCES DONEEEEEEEE ] -----------------
  // ------------------------------------------------------------------

