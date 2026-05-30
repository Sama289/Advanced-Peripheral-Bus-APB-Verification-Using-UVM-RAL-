package my_test_pkg;


  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import my_env_pkg::*;
  import my_ral_pkg::*;           
  import my_reg_sequences_pkg::*;
  import apb_reg_block_pkg::*;

  `define create(type , inst_name)  type::type_id::create(inst_name,this);

  class my_test extends uvm_test;
    `uvm_component_utils(my_test)

    my_env        env;
    apb_reg_block reg_block;

    function new (string name = "my_test" , uvm_component parent = null);
      super.new(name , parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      // 1. Enable UVM Coverage and Build the Register Block
      uvm_reg::include_coverage("*", UVM_CVR_ALL);
      reg_block = apb_reg_block::type_id::create("reg_block");
      reg_block.build();

      // 2. Set the Backdoor HDL Path mapping to top.sv
      reg_block.add_hdl_path("top.DUT");
      reg_block.lock_model();

      // 3. Set into config_db for my_env to grab
      uvm_config_db#(apb_reg_block)::set(this, "*", "reg_block", reg_block);

      env = `create(my_env , "env");
      `uvm_info("MY_TEST" , "TEST BUILT" , UVM_LOW);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
      // Declare all 5 register sequences
      ctrl_reg_seq seq_ctrl;
      reg1_reg_seq seq_reg1;
      reg2_reg_seq seq_reg2;
      reg3_reg_seq seq_reg3;
      reg4_reg_seq seq_reg4;

      phase.raise_objection(this);
      `uvm_info("RUN TEST" , "STARTING ALL RAL SEQUENCES" , UVM_LOW);

      // --- Start Sequence 1: CNTRL ---
      seq_ctrl = ctrl_reg_seq::type_id::create("seq_ctrl");
      seq_ctrl.reg_block = reg_block; // Assign pointer
      seq_ctrl.start(env.agent.seqr);

      // --- Start Sequence 2: REG1 ---
      seq_reg1 = reg1_reg_seq::type_id::create("seq_reg1");
      seq_reg1.reg_block = reg_block; 
      seq_reg1.start(env.agent.seqr);

      // --- Start Sequence 3: REG2 ---
      seq_reg2 = reg2_reg_seq::type_id::create("seq_reg2");
      seq_reg2.reg_block = reg_block; 
      seq_reg2.start(env.agent.seqr);

      // --- Start Sequence 4: REG3 ---
      seq_reg3 = reg3_reg_seq::type_id::create("seq_reg3");
      seq_reg3.reg_block = reg_block; 
      seq_reg3.start(env.agent.seqr);

      // --- Start Sequence 5: REG4 ---
      seq_reg4 = reg4_reg_seq::type_id::create("seq_reg4");
      seq_reg4.reg_block = reg_block; 
      seq_reg4.start(env.agent.seqr);

      phase.drop_objection(this);  
    endtask

  endclass

endpackage