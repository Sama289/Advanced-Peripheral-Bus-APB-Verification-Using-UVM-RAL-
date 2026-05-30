package my_ral_pkg;

import uvm_pkg::*;
  `include "uvm_macros.svh"
  import my_sequence_item_pkg::*;
  `include "apb_adapter.sv"


  //-------------------------------------------------------------
  //  CNTRL Register  (Address: 0x00)
  //  Width : 32-bit , [3:0] RW  , [31:4] Reserved RO
  //  Reset : 0x00000000
  //-------------------------------------------------------------

  class cntrl_reg extends uvm_reg;
    `uvm_object_utils(cntrl_reg)

    // ---- Register Fields ----
    rand uvm_reg_field CTRL0;
    rand uvm_reg_field CTRL1;
    rand uvm_reg_field CTRL2;
    rand uvm_reg_field CTRL3;
         uvm_reg_field RESERVED;

    // ---- Covergroup ----
    covergroup cntrl_cg with function sample(uvm_reg_data_t val);
      // Cover all 4-bit CTRL combinations
      CTRL_ALL: coverpoint val[3:0] {
        bins all_zeros     = {4'b0000};
        bins all_ones      = {4'b1111};
        bins ctrl0_only    = {4'b0001};
        bins ctrl1_only    = {4'b0010};
        bins ctrl2_only    = {4'b0100};
        bins ctrl3_only    = {4'b1000};
        bins lower_two     = {4'b0011};
        bins upper_two     = {4'b1100};
        bins alternating_a = {4'b0101};
        bins alternating_b = {4'b1010};
        bins others        = default;
      }
      // Individual bit coverage
      CTRL0_BIT: coverpoint val[0] { bins low = {0}; bins high = {1}; }
      CTRL1_BIT: coverpoint val[1] { bins low = {0}; bins high = {1}; }
      CTRL2_BIT: coverpoint val[2] { bins low = {0}; bins high = {1}; }
      CTRL3_BIT: coverpoint val[3] { bins low = {0}; bins high = {1}; }
      // Cross coverage: CTRL0 x CTRL1
      CTRL01_CROSS: cross CTRL0_BIT, CTRL1_BIT;
    endgroup : cntrl_cg

    // ---- Constraints ----
    // Reserved field must always be zero as in specs 
    constraint reserved_zero_c { RESERVED.value == 28'h0; }
    // Constrain to valid lower-nibble patterns only
    constraint valid_ctrl_c    { 
    (CTRL0.value | CTRL1.value |CTRL2.value | CTRL3.value) inside {[0:1]};
    }

    // ---- Constructor ----
    function new(string name = "cntrl_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
      cntrl_cg = new();
    endfunction

    // ---- Build ----
    virtual function void build();
      CTRL0    = uvm_reg_field::type_id::create("CTRL0");
      CTRL1    = uvm_reg_field::type_id::create("CTRL1");
      CTRL2    = uvm_reg_field::type_id::create("CTRL2");
      CTRL3    = uvm_reg_field::type_id::create("CTRL3");
      RESERVED = uvm_reg_field::type_id::create("RESERVED");
      // parent size lsb access vol reset has_rst is_rand individually_acc
      CTRL0.configure   (this, 1,  0,  "RW",   0,  1'b0,    1,       1,       0);
      CTRL1.configure   (this, 1,  1,  "RW",   0,  1'b0,    1,       1,       0);
      CTRL2.configure   (this, 1,  2,  "RW",   0,  1'b0,    1,       1,       0);
      CTRL3.configure   (this, 1,  3,  "RW",   0,  1'b0,    1,       1,       0);
      RESERVED.configure(this, 28, 4,  "RO",   0,  28'h0,   1,       0,       0);
    endfunction

    // ---- Manual sample hook ----
    function void sample_cg(uvm_reg_data_t val);
      cntrl_cg.sample(val);
    endfunction

  endclass : cntrl_reg



/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////


  //-------------------------------------------------------------
  //  REG1 Register  (Address: 0x04)
  //  Width : 32-bit  ,  [31:0] RW  ,  Reset : 0x00000000
  //-------------------------------------------------------------
  class reg1_reg extends uvm_reg;
    `uvm_object_utils(reg1_reg)

    rand uvm_reg_field DATA;

    // ---- Covergroup ----
    covergroup reg1_cg with function sample(uvm_reg_data_t val);
      LOW_BYTE:  coverpoint val[7:0]  {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
      }
      HIGH_BYTE: coverpoint val[31:24] {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
      }
      FULL_WORD: coverpoint val {
        bins all_zeros  = {32'h00000000};
        bins all_ones   = {32'hFFFFFFFF};
        bins walking_b0 = {32'h00000001};
        bins walking_b8 = {32'h00000100};
        bins walking_b16= {32'h00010000};
        bins walking_b24= {32'h01000000};
        bins others     = default;
      }
    endgroup : reg1_cg

    // ---- Constraints ----
    constraint nonzero_c   { DATA.value != 32'h0; }
    constraint no_all_ones { DATA.value != 32'hFFFF_FFFF; }

    function new(string name = "reg1_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
      reg1_cg = new();
    endfunction

    virtual function void build();
      DATA = uvm_reg_field::type_id::create("DATA");
      DATA.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 0);
    endfunction

    function void sample_cg(uvm_reg_data_t val);
      reg1_cg.sample(val);
    endfunction

  endclass : reg1_reg



/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////


  //-------------------------------------------------------------
  //  REG2 Register  (Address: 0x08)
  //  Width : 32-bit  ,  [31:0] RW  ,  Reset : 0x00000000
  //-------------------------------------------------------------
  class reg2_reg extends uvm_reg;
    `uvm_object_utils(reg2_reg)

    rand uvm_reg_field DATA;

    covergroup reg2_cg with function sample(uvm_reg_data_t val);
      LOW_BYTE:  coverpoint val[7:0]  {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
      }
      HIGH_BYTE: coverpoint val[31:24] {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
      }
      NIBBLE_PATTERN: coverpoint val[3:0] {
        bins nibble_0 = {4'h0};
        bins nibble_F = {4'hF};
        bins nibble_A = {4'hA};
        bins nibble_5 = {4'h5};
        bins others   = default;
      }
      FULL_WORD: coverpoint val {
        bins all_zeros = {32'h00000000};
        bins all_ones  = {32'hFFFFFFFF};
        bins checkerA  = {32'hA5A5A5A5};
        bins checkerB  = {32'h5A5A5A5A};
        bins others    = default;
      }
    endgroup : reg2_cg

    // ---- Constraints ----
    constraint checker_pattern_c {
      DATA.value inside {32'hA5A5A5A5, 32'h5A5A5A5A,
                         32'h00FF00FF, 32'hFF00FF00,
                         32'h0F0F0F0F, 32'hF0F0F0F0,
                         32'h00000000, 32'hFFFFFFFF};
    }

    function new(string name = "reg2_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
      reg2_cg = new();
    endfunction

    virtual function void build();
      DATA = uvm_reg_field::type_id::create("DATA");
      DATA.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 0);
    endfunction

    function void sample_cg(uvm_reg_data_t val);
      reg2_cg.sample(val);
    endfunction

  endclass : reg2_reg




/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////


  //-------------------------------------------------------------
  //  REG3 Register  (Address: 0x0C)
  //  Width : 32-bit  ,  [31:0] RW  ,  Reset : 0x00000000
  //-------------------------------------------------------------
  class reg3_reg extends uvm_reg;
    `uvm_object_utils(reg3_reg)

    rand uvm_reg_field DATA;

    covergroup reg3_cg with function sample(uvm_reg_data_t val);
      BYTE0: coverpoint val[7:0]   { bins zero={8'h00}; bins max={8'hFF}; bins mid={[8'h01:8'hFE]}; }
      BYTE1: coverpoint val[15:8]  { bins zero={8'h00}; bins max={8'hFF}; bins mid={[8'h01:8'hFE]}; }
      BYTE2: coverpoint val[23:16] { bins zero={8'h00}; bins max={8'hFF}; bins mid={[8'h01:8'hFE]}; }
      BYTE3: coverpoint val[31:24] { bins zero={8'h00}; bins max={8'hFF}; bins mid={[8'h01:8'hFE]}; }
      FULL_WORD: coverpoint val {
        bins all_zeros = {32'h00000000};
        bins all_ones  = {32'hFFFFFFFF};
        bins others    = default;
      }
      // Cross of byte0 and byte3 patterns
      CORNER_CROSS: cross BYTE0, BYTE3;
    endgroup : reg3_cg

    // ---- Constraints ----
    constraint byte_aligned_c {
      DATA.value[7:0]   inside {8'h00, 8'hFF, 8'h55, 8'hAA};
      DATA.value[31:24] inside {8'h00, 8'hFF, 8'h55, 8'hAA};
    }

    function new(string name = "reg3_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
      reg3_cg = new();
    endfunction

    virtual function void build();
      DATA = uvm_reg_field::type_id::create("DATA");
      DATA.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 0);
    endfunction

    function void sample_cg(uvm_reg_data_t val);
      reg3_cg.sample(val);
    endfunction

  endclass : reg3_reg




/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////



  //-------------------------------------------------------------
  //  REG4 Register  (Address: 0x10)
  //  Width : 32-bit  ,  [31:0] RW  ,  Reset : 0x00000000
  //-------------------------------------------------------------
  class reg4_reg extends uvm_reg;
    `uvm_object_utils(reg4_reg)

    rand uvm_reg_field DATA;

    covergroup reg4_cg with function sample(uvm_reg_data_t val);
      LOW_BYTE:  coverpoint val[7:0]  {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
      }
      HIGH_BYTE: coverpoint val[31:24] {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
      }
      MSB_LSB: coverpoint {val[31], val[0]} {
        bins both_zero = {2'b00};
        bins both_one  = {2'b11};
        bins msb_only  = {2'b10};
        bins lsb_only  = {2'b01};
      }
      FULL_WORD: coverpoint val {
        bins all_zeros  = {32'h00000000};
        bins all_ones   = {32'hFFFFFFFF};
        bins upper_half = {[32'h80000000:32'hFFFFFFFF]};
        bins lower_half = {[32'h00000001:32'h7FFFFFFF]};
      }
    endgroup : reg4_cg

    // ---- Constraints ----
    constraint power_of_two_c {
      $countones(DATA.value) inside {[1:16]};
    }

    function new(string name = "reg4_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
      reg4_cg = new();
    endfunction

    virtual function void build();
      DATA = uvm_reg_field::type_id::create("DATA");
      DATA.configure(this, 32, 0, "RW", 0, 32'h0, 1, 1, 0);
    endfunction

    function void sample_cg(uvm_reg_data_t val);
      reg4_cg.sample(val);
    endfunction

  endclass : reg4_reg


endpackage : my_ral_pkg