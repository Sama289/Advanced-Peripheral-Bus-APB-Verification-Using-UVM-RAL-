package apb_regs_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  //-------------------------------------------------------------
  //  CNTRL Register  (Address: 0x00)
  //  Width : 32-bit , [3:0] RW  , [31:4] Reserved RO
  //  Reset : 0
  //-------------------------------------------------------------

  class cntrl_reg extends uvm_reg;
    `uvm_object_utils(cntrl_reg) //
    
    // ---- Register Fields ----
  
    // NOTE for constraints: Just a pointer, it doesn't know its size yet
    rand uvm_reg_field reg1_en;    // bit[0]  
    rand uvm_reg_field reg2_en;    // bit[1]
    rand uvm_reg_field reg3_en;    // bit[2]
    rand uvm_reg_field reg4_en;    // bit[3]
    rand uvm_reg_field RESERVED_28; // bits [31:4] reserved :) han-constrain
 
    rand bit [3:0] pattern_sel; // for enabling variations (Increased to 4 bits)
    //----------------------------------------------
    // ---- Constraints for the fields rand ----
    //----------------------------------------------
    constraint ctrl_patterns_c {
      
      // Control the probability of each pattern hitting
      pattern_sel dist {
        0 :/ 2,  // All OFF
        1 :/ 2,  // All ON
        2 :/ 10, // Alternating (1010)
        3 :/ 10, // Alternating (0101)
        4 :/ 10, // Upper 2 regs (reg4 & reg3 ON)
        5 :/ 10, // Lower 2 regs (reg2 & reg1 ON)
        6 :/ 10, // Middle regs (reg3 & reg2 ON)
        [7:15] :/ 46 // completely random mix
      };
      

      // Define what happens for each pattern (ADDED .value[0])
      (pattern_sel == 0) -> { reg4_en.value[0] == 0; reg3_en.value[0] == 0; reg2_en.value[0] == 0; reg1_en.value[0] == 0; }
      (pattern_sel == 1) -> { reg4_en.value[0] == 1; reg3_en.value[0] == 1; reg2_en.value[0] == 1; reg1_en.value[0] == 1; }
      (pattern_sel == 2) -> { reg4_en.value[0] == 1; reg3_en.value[0] == 0; reg2_en.value[0] == 1; reg1_en.value[0] == 0; }
      (pattern_sel == 3) -> { reg4_en.value[0] == 0; reg3_en.value[0] == 1; reg2_en.value[0] == 0; reg1_en.value[0] == 1; }

      (pattern_sel == 4) -> { reg4_en.value[0] == 1; reg3_en.value[0] == 1; reg2_en.value[0] == 0; reg1_en.value[0] == 0; }
      (pattern_sel == 5) -> { reg4_en.value[0] == 0; reg3_en.value[0] == 0; reg2_en.value[0] == 1; reg1_en.value[0] == 1; }
      (pattern_sel == 6) -> { reg4_en.value[0] == 0; reg3_en.value[0] == 1; reg2_en.value[0] == 1; reg1_en.value[0] == 0; }

      // For "Random Mix" state (7 to 15)
      if (pattern_sel >= 7) {
        reg1_en.value[0] dist { 1'b0 := 30 , 1'b1 := 70 };
        reg2_en.value[0] dist { 1'b0 := 30 , 1'b1 := 70 };
        reg3_en.value[0] dist { 1'b0 := 30 , 1'b1 := 70 };
        reg4_en.value[0] dist { 1'b0 := 30 , 1'b1 := 70 };
      }
    } 

    constraint reserved_zero_c { 
      RESERVED_28.value[27:0] == 28'h0000000; 
    }

    // Safe Guard kda - update [msh hasah will comment it w oli ra2ek :)]
    // constraint valid_ctrl_c    { 
    //   ( reg1_en.value |reg2_en.value | reg3_en.value | reg4_en.value) inside {[0:1]};
    // }





    `ifdef COV_EN
      //----------------------------------------------
      // -------- Coverage for the CNTRL_reg --------
      //----------------------------------------------
      
      covergroup ctrl_reg_cg with function sample(uvm_reg_data_t data, bit is_read);
        option.per_instance = 1;

        // Full 4-bit value coverage
        cp_ctrl_value : coverpoint data[3:0] {
          bins all_zeros        = { 4'b0000 };
          bins all_ones         = { 4'b1111 };
          bins alternating_a    = { 4'b1010 };
          bins alternating_b    = { 4'b0101 };
          bins lower_two        = { 4'b0011 };
          bins upper_two        = { 4'b1100 };
          bins one_reg_set[]    = { 4'b0001, 4'b0010, 4'b0100, 4'b1000 };
          bins others           = default;
        }
      
      cp_reserved : coverpoint data[31:4] {
        illegal_bins non_zero = { [28'h0000001 : 28'hFFFFFFF] }; 
      } 
        // ENABLES is toggle
        cp_reg1_en  : coverpoint data[0] { bins off = {0}; bins on = {1}; }
        cp_reg2_en  : coverpoint data[1] { bins off = {0}; bins on = {1}; }
        cp_reg3_en  : coverpoint data[2] { bins off = {0}; bins on = {1}; }
        cp_reg4_en  : coverpoint data[3] { bins off = {0}; bins on = {1}; }
   
        // Read vs Write access coverage
        cp_access   : coverpoint is_read { 
          bins write = {0}; 
          bins read  = {1}; 
        }

        // Cross: value pattern x access type
        cross_val_access : cross cp_ctrl_value, cp_access;
   
      endgroup
    



    // ---- Standard UVM Sample Hook (Replaced sample_values) ----
    virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en, bit is_read, uvm_reg_map map);
      uvm_reg_data_t val;
      
      super.sample(data, byte_en, is_read, map); // hya bta5od 4 args lazm a pass it to it 
      
      if (has_coverage(UVM_CVR_FIELD_VALS)) begin // Is this coverage type currently ENABLED at runtime?
        ctrl_reg_cg.sample(data, is_read);        // the door is currently open ?
      end
  
    endfunction

  `endif





  //////////////
  ///[Constrctor]////

    function new(string name = "ctrl_reg");
      super.new(name, 32, UVM_CVR_ALL);
    `ifdef COV_EN   
      if (has_coverage(UVM_CVR_FIELD_VALS)) begin // Does this register CLASS support this coverage type at all?
        ctrl_reg_cg = new();                      // the door exists ?  
      end
    `endif
    endfunction

  //////////////
  /////////////

    //--------------------------------------------------------
    // ---- Build ( build and configure el-fields ) ----
    //--------------------------------------------------------

    virtual function void build();
      
      reg1_en     = uvm_reg_field::type_id::create("reg1_en");
      reg2_en     = uvm_reg_field::type_id::create("reg2_en");
      reg3_en     = uvm_reg_field::type_id::create("reg3_en");
      reg4_en     = uvm_reg_field::type_id::create("reg4_en");
      RESERVED_28 = uvm_reg_field::type_id::create("RESERVED_28");

      // configure(parent, size, lsb, access, vol, reset, has_rst, is_rand, ind_acc)
      reg1_en.configure    (this, 1,  0, "RW", 0, 1'b0,  1, 1, 1); 
      reg2_en.configure    (this, 1,  1, "RW", 0, 1'b0,  1, 1, 1);
      reg3_en.configure    (this, 1,  2, "RW", 0, 1'b0,  1, 1, 1);
      reg4_en.configure    (this, 1,  3, "RW", 0, 1'b0,  1, 1, 1);
      RESERVED_28.configure(this, 28, 4, "RO", 0, 28'h0, 1, 0, 0); // is_rand=0 since it's reserved RO
    
    endfunction

  endclass





/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////





  //-------------------------------------------------------------
  //  REG1 Register  (Address: 0x04)
  //  Width : 32-bit  ,  [31:0] RW  ,  Reset : 0x00000000
  //-------------------------------------------------------------
  class reg1 extends uvm_reg;
    `uvm_object_utils(reg1)

    // ---- Register fields ----
    rand uvm_reg_field data_1;

    //----------------------------------------------
    // ------ Constraints for the fields rand -----
    //----------------------------------------------
    constraint data_c {      
      data_1.value[31:0] dist {
        32'h0000_0000 :/ 5,    // All Zeros
        32'hFFFF_FFFF :/ 5,    // All Ones
        32'hAAAA_AAAA :/ 5,    // Alternating A (1010...)
        32'h5555_5555 :/ 5,    // Alternating 5 (0101...)

        [32'h0000_0001 : 32'h3FFF_FFFF] :/ 20, // Q1 
        [32'h4000_0000 : 32'h7FFF_FFFF] :/ 20, // Q2
        [32'h8000_0000 : 32'hBFFF_FFFF] :/ 20, // Q3
        [32'hC000_0000 : 32'hFFFF_FFFE] :/ 20  // Q4 
      };
    }

    //----------------------------------------------
    // -------------- Coverage  --------------------
    //----------------------------------------------

  `ifdef COV_EN
    covergroup reg1_cg with function sample(uvm_reg_data_t bus_data, bit is_read);
      option.per_instance = 1;

      cp_FULL_WORD : coverpoint bus_data {
        bins zero         = { 32'h0000_0000 };
        bins max_val      = { 32'hFFFF_FFFF };
        bins alt_a        = { 32'hAAAA_AAAA }; // 101010...
        bins alt_5        = { 32'h5555_5555 }; 
        
        // The 32-bit space divided into 4 equal ranges
        bins ranges[4]    = { [32'h0000_0000 : 32'hFFFF_FFFF] };
        bins others       = default; 
      }
 
      cp_HIGH_byte : coverpoint bus_data[31:24] {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
        bins others    = default;
      }
 
      cp_LOW_byte : coverpoint bus_data[7:0]  {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
        bins others    = default;
      }

      cp_access   : coverpoint is_read { 
        bins write = {0}; 
        bins read  = {1}; 
      }

      cross_msb_lsb_access   : cross cp_HIGH_byte, cp_access, cp_LOW_byte;
      cross_full_access      : cross cp_FULL_WORD, cp_access;
 
    endgroup

    
    virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en, bit is_read, uvm_reg_map map);
      super.sample(data, byte_en, is_read, map); 
      if (has_coverage(UVM_CVR_FIELD_VALS)) begin
        reg1_cg.sample(data, is_read);
      end

    endfunction
  `endif  

    //-------------------------------------------------------- 
    // ------------------------ Constructor -----------------
    //--------------------------------------------------------
    function new(string name = "reg1");
      super.new(name, 32, UVM_CVR_ALL);
      `ifdef COV_EN 
        if (has_coverage(UVM_CVR_FIELD_VALS)) begin
          reg1_cg = new(); 
        end
      `endif
    endfunction


    //--------------------------------------------------------
    // ---- Build ( build and configure el-fields ) ----
    //--------------------------------------------------------
    virtual function void build();
      data_1 = uvm_reg_field::type_id::create("data_1");
      // configure(parent, size, lsb, access, vol, reset, has_rst, is_rand, ind_acc)
      data_1.configure(this, 32, 0, "RW", 0, 32'h0000_0000, 1, 1, 0);
    endfunction


  endclass




/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////





  //-------------------------------------------------------------
  //  REG2 Register  (Address: 0x08)
  //  Width : 32-bit  ,  [31:0] RW  ,  Reset : 0x00000000
  //-------------------------------------------------------------
    class reg2 extends uvm_reg;
    `uvm_object_utils(reg2)

    // ---- Register fields ----
    rand uvm_reg_field data_2;

    //----------------------------------------------
    // ------ Constraints for the fields rand -----
    //----------------------------------------------
    constraint data_c {      
      data_2.value[31:0] dist {
        32'h0000_0000 :/ 5,    // All Zeros
        32'hFFFF_FFFF :/ 5,    // All Ones
        32'hAAAA_AAAA :/ 5,    // Alternating A (1010...)
        32'h5555_5555 :/ 5,    // Alternating 5 (0101...)

        [32'h0000_0001 : 32'h3FFF_FFFF] :/ 20, // Q1 
        [32'h4000_0000 : 32'h7FFF_FFFF] :/ 20, // Q2
        [32'h8000_0000 : 32'hBFFF_FFFF] :/ 20, // Q3
        [32'hC000_0000 : 32'hFFFF_FFFE] :/ 20  // Q4 
      };
    }

    //----------------------------------------------
    // -------------- Coverage  --------------------
    //----------------------------------------------

  `ifdef COV_EN  
    covergroup reg2_cg with function sample(uvm_reg_data_t bus_data, bit is_read);
      option.per_instance = 1;

      cp_FULL_WORD_2 : coverpoint bus_data {
        bins zero         = { 32'h0000_0000 };
        bins max_val      = { 32'hFFFF_FFFF };
        bins alt_a        = { 32'hAAAA_AAAA }; // 101010...
        bins alt_5        = { 32'h5555_5555 }; 
        
        // The 32-bit space divided into 4 equal ranges
        bins ranges[4]    = { [32'h0000_0000 : 32'hFFFF_FFFF] };
        bins others       = default; 
      }
 
      cp_HIGH_byte_2 : coverpoint bus_data[31:24] {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
        bins others    = default;
      }
 
      cp_LOW_byte_2 : coverpoint bus_data[7:0]  {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
        bins others    = default;
      }

      cp_access_2   : coverpoint is_read { 
        bins write = {0}; 
        bins read  = {1}; 
      }

      cross_msb_lsb_access_2   : cross cp_HIGH_byte_2, cp_access_2, cp_LOW_byte_2;
      cross_full_access_2      : cross cp_FULL_WORD_2, cp_access_2;
 
    endgroup

    
    virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en, bit is_read, uvm_reg_map map);
      super.sample(data, byte_en, is_read, map); 
      if (has_coverage(UVM_CVR_FIELD_VALS)) begin
        reg2_cg.sample(data, is_read);
      end

    endfunction
  `endif  

    //-------------------------------------------------------- 
    // ------------------------ Constructor -----------------
    //--------------------------------------------------------
    function new(string name = "reg2");
      super.new(name, 32, UVM_CVR_ALL);
      `ifdef COV_EN 
        if (has_coverage(UVM_CVR_FIELD_VALS)) begin
          reg2_cg = new(); 
        end
      `endif
    endfunction


    //--------------------------------------------------------
    // ---- Build ( build and configure el-fields ) ----
    //--------------------------------------------------------
    virtual function void build();
      data_2 = uvm_reg_field::type_id::create("data_2");
      // configure(parent, size, lsb, access, vol, reset, has_rst, is_rand, ind_acc)
      data_2.configure(this, 32, 0, "RW", 0, 32'h0000_0000, 1, 1, 0);
    endfunction


  endclass




/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////





  //-------------------------------------------------------------
  //  REG3 Register  (Address: 0x0C)
  //  Width : 32-bit  ,  [31:0] RW  ,  Reset : 0x00000000
  //-------------------------------------------------------------
  class reg3 extends uvm_reg;
    `uvm_object_utils(reg3)
    // ---- Register fields ----
    rand uvm_reg_field data_3;

    //----------------------------------------------
    // ------ Constraints for the fields rand -----
    //----------------------------------------------
    constraint data_c {      
      data_3.value[31:0] dist {
        32'h0000_0000 :/ 5,    // All Zeros
        32'hFFFF_FFFF :/ 5,    // All Ones
        32'hAAAA_AAAA :/ 5,    // Alternating A (1010...)
        32'h5555_5555 :/ 5,    // Alternating 5 (0101...)

        [32'h0000_0001 : 32'h3FFF_FFFF] :/ 20, // Q1 
        [32'h4000_0000 : 32'h7FFF_FFFF] :/ 20, // Q2
        [32'h8000_0000 : 32'hBFFF_FFFF] :/ 20, // Q3
        [32'hC000_0000 : 32'hFFFF_FFFE] :/ 20  // Q4 
      };
    }

    //----------------------------------------------
    // -------------- Coverage  --------------------
    //----------------------------------------------

  `ifdef COV_EN  
    covergroup reg3_cg with function sample(uvm_reg_data_t bus_data, bit is_read);
      option.per_instance = 1;

      cp_FULL_WORD_3 : coverpoint bus_data {
        bins zero         = { 32'h0000_0000 };
        bins max_val      = { 32'hFFFF_FFFF };
        bins alt_a        = { 32'hAAAA_AAAA }; // 101010...
        bins alt_5        = { 32'h5555_5555 }; 
        
        // The 32-bit space divided into 4 equal ranges
        bins ranges[4]    = { [32'h0000_0000 : 32'hFFFF_FFFF] };
        bins others       = default; 
      }
 
      cp_HIGH_byte_3 : coverpoint bus_data[31:24] {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
        bins others    = default;
      }
 
      cp_LOW_byte_3 : coverpoint bus_data[7:0]  {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
        bins others    = default;
      }

      cp_access_3   : coverpoint is_read { 
        bins write = {0}; 
        bins read  = {1}; 
      }

      cross_msb_lsb_access_3   : cross cp_HIGH_byte_3, cp_access_3, cp_LOW_byte_3;
      cross_full_access_3      : cross cp_FULL_WORD_3, cp_access_3;
 
    endgroup


    virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en, bit is_read, uvm_reg_map map);
      super.sample(data, byte_en, is_read, map); 
      if (has_coverage(UVM_CVR_FIELD_VALS)) begin
        reg3_cg.sample(data, is_read);
      end

    endfunction

  `endif

    //-------------------------------------------------------- 
    // ------------------------ Constructor -----------------
    //--------------------------------------------------------
    function new(string name = "reg3");
      super.new(name, 32, UVM_CVR_ALL);
      `ifdef COV_EN 
        if (has_coverage(UVM_CVR_FIELD_VALS)) begin
          reg3_cg = new(); 
        end
      `endif
    endfunction


    //--------------------------------------------------------
    // ---- Build ( build and configure el-fields ) ----
    //--------------------------------------------------------
    virtual function void build();
      data_3 = uvm_reg_field::type_id::create("data_3");
      // configure(parent, size, lsb, access, vol, reset, has_rst, is_rand, ind_acc)
      data_3.configure(this, 32, 0, "RW", 0, 32'h0000_0000, 1, 1, 0);
    endfunction

  endclass : reg3





/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////





  //-------------------------------------------------------------
  //  REG4 Register  (Address: 0x10)
  //  Width : 32-bit  ,  [31:0] RW  ,  Reset : 0x00000000
  //-------------------------------------------------------------
  class reg4 extends uvm_reg;
      `uvm_object_utils(reg4)
    // ---- Register fields ----
    rand uvm_reg_field data_4;

    //----------------------------------------------
    // ------ Constraints for the fields rand -----
    //----------------------------------------------
    constraint data_c {      
      data_4.value[31:0] dist {
        32'h0000_0000 :/ 5,    // All Zeros
        32'hFFFF_FFFF :/ 5,    // All Ones
        32'hAAAA_AAAA :/ 5,    // Alternating A (1010...)
        32'h5555_5555 :/ 5,    // Alternating 5 (0101...)

        [32'h0000_0001 : 32'h3FFF_FFFF] :/ 20, // Q1 
        [32'h4000_0000 : 32'h7FFF_FFFF] :/ 20, // Q2
        [32'h8000_0000 : 32'hBFFF_FFFF] :/ 20, // Q3
        [32'hC000_0000 : 32'hFFFF_FFFE] :/ 20  // Q4 
      };
    }

    //----------------------------------------------
    // -------------- Coverage  --------------------
    //----------------------------------------------

  `ifdef COV_EN  
    covergroup reg4_cg with function sample(uvm_reg_data_t bus_data, bit is_read);
      option.per_instance = 1;

      cp_FULL_WORD_4 : coverpoint bus_data {
        bins zero         = { 32'h0000_0000 };
        bins max_val      = { 32'hFFFF_FFFF };
        bins alt_a        = { 32'hAAAA_AAAA }; // 101010...
        bins alt_5        = { 32'h5555_5555 }; 
        
        // The 32-bit space divided into 4 equal ranges
        bins ranges[4]    = { [32'h0000_0000 : 32'hFFFF_FFFF] };
        bins others       = default; 
      }
 
      cp_HIGH_byte_4 : coverpoint bus_data[31:24] {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
        bins others    = default;
      }
 
      cp_LOW_byte_4 : coverpoint bus_data[7:0]  {
        bins zero      = {8'h00};
        bins max_val   = {8'hFF};
        bins mid_range = {[8'h01:8'hFE]};
        bins others    = default;
      }

      cp_access_4   : coverpoint is_read { 
        bins write = {0}; 
        bins read  = {1}; 
      }

      cross_msb_lsb_access_4   : cross cp_HIGH_byte_4, cp_access_4, cp_LOW_byte_4;
      cross_full_access_4      : cross cp_FULL_WORD_4, cp_access_4;
 
    endgroup

    virtual function void sample(uvm_reg_data_t data, uvm_reg_data_t byte_en, bit is_read, uvm_reg_map map);
      super.sample(data, byte_en, is_read, map); 
      if (has_coverage(UVM_CVR_FIELD_VALS)) begin
        reg4_cg.sample(data, is_read);
      end

    endfunction

  `endif  

    //-------------------------------------------------------- 
    // ------------------------ Constructor -----------------
    //--------------------------------------------------------
    function new(string name = "reg4");
      super.new(name, 32, UVM_CVR_ALL);
      `ifdef COV_EN 
        if (has_coverage(UVM_CVR_FIELD_VALS)) begin
          reg4_cg = new(); 
        end
      `endif
    endfunction


    //--------------------------------------------------------
    // ---- Build ( build and configure el-fields ) ----
    //--------------------------------------------------------
    virtual function void build();
      data_4 = uvm_reg_field::type_id::create("data_4");
      // configure(parent, size, lsb, access, vol, reset, has_rst, is_rand, ind_acc)
      data_4.configure(this, 32, 0, "RW", 0, 32'h0000_0000, 1, 1, 0);
    endfunction
  endclass

endpackage