/*-------------------------------------
Test build_phase  ->  config_db::set(reg_block)
Env  build_phase  ->  config_db::get(reg_block)  
Test run_phase    ->  creates & starts sequences and handover the reg_block (pointer)
*/

package my_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import my_env_pkg::*;
  import apb_regs_pkg::*;
  import apb_reg_sequences_pkg::*;
  import apb_reg_block_pkg::*;

  `define create(type , inst_name)  type::type_id::create(inst_name,this); // This is a macro to save the much code into small one for constructing
                                                                           // U can use the old one normally no problem also    
  class my_test extends uvm_test;
    `uvm_component_utils(my_test)

    my_env  env;
    top_reg_block  reg_model;
    virtual APB_If  vif;          // needed to drive presetn for reset test

    int LOOP_COUNT;

    // Normally was here ::Declare handles of ral sequences 




  //////////////
  /////////////  

    function new (string name = "my_test" , uvm_component parent = null);
  	 super.new(name , parent);
    endfunction




  //////////////
  /////////////  

    function void build_phase(uvm_phase phase);
    	super.build_phase(phase);
      env       = `create(my_env , "env");
      `uvm_info("MY_TEST" , "TEST BUILT" , UVM_LOW);
  	  
      // -------- FOR RAL INTEGRATION ---------------------

      // ----- Enable UVM Coverage and Build the Register Block
      uvm_reg::include_coverage("*", UVM_CVR_ALL);
       reg_model = top_reg_block::type_id::create("reg_model");
       reg_model.build();

      // ----- Set the Backdoor HDL Path mapping to top.sv 3shan byz3l :)
       reg_model.add_hdl_path("top.DUT");
       reg_model.lock_model(); 

      //Set into config_db for my_env to grab 
      uvm_config_db#(top_reg_block)::set(this, "*", "reg_block",  reg_model );

      // ---- Get the virtual interface so run_phase can drive presetn ----
      if (!uvm_config_db#(virtual APB_If)::get(this, "*", "APB_vif", vif))
        `uvm_fatal("MY_TEST", "Could not get APB_vif from config_db")
      
      // ---- NORMALLY WAS HERE 
      // c_seq  = CNTRL_reg_seq::type_id::create("c_seq");
      // r1_seq = reg1_seq::type_id::create("r1_seq");
      // r2_seq = reg2_seq::type_id::create("r2_seq");
      // r3_seq = reg3_seq::type_id::create("r3_seq");
      // r4_seq = reg4_seq::type_id::create("r4_seq");
      // //--------------

    endfunction



  //////////////
  /////////////  

    function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      uvm_top.print_topology();
      reg_model.print();
    endfunction



  //////////////
  ///////////// 


 
    function void start_of_simulation_phase(uvm_phase phase);
      super.start_of_simulation_phase(phase);
      uvm_top.set_report_verbosity_level_hier(UVM_NONE);
 
 
    endfunction

//////////////
/////////////


    task run_phase(uvm_phase phase);
      
      //-------------------------- ADDED_FOR_RAL_INTEGRATION ---------------------------------
      // [Assume that save my resources ] Ha3ml kolo hena 3shan y- only exist in memory while they are actively running.
      
      // ---- Declare handles of ral sequences ---
         CNTRL_reg_seq  c_seq;
         reg1_seq       seq_reg1;
         reg2_seq       seq_reg2;
         reg3_seq       seq_reg3;
         reg4_seq       seq_reg4;

      `uvm_info("RUN TEST" , "TEST RUN_PHASE HERE" , UVM_LOW);
      phase.raise_objection(this);
        `uvm_info("RUN TEST" , "STARTING ALL RAL SEQUENCES" , UVM_LOW)


        `uvm_info("RUN TEST", "APPLYING RESET (presetn = 0)", UVM_LOW)
        vif.presetn = 1'b0;
        repeat(5) @(posedge vif.pclk);   // hold reset for 5 clocks
        vif.presetn = 1'b1;
        repeat(2) @(posedge vif.pclk);   // 2 clocks settling time after release
        `uvm_info("RUN TEST", "RESET RELEASED (presetn = 1)", UVM_LOW)

        // iNSTEAD OF POINTER ASSIGNMENT : mmkn a a put reg_block in config db w a get it in each sequences task body ?
        `ifdef COV_EN 
        LOOP_COUNT = 0;
          repeat(100) begin
        `endif

          $display("TEST LOOP %0D", LOOP_COUNT);
        // --- Start Sequence 1: CNTRL ---
        c_seq = CNTRL_reg_seq::type_id::create("c_seq");
        c_seq.reg_block = reg_model; // Assign pointer
        c_seq.start(env.agent.seqr);        

        // --- Start Sequence 2: REG1 ---
        seq_reg1 = reg1_seq::type_id::create("seq_reg1");
        seq_reg1.reg_block = reg_model; 
        seq_reg1.start(env.agent.seqr);

        // --- Start Sequence 3: REG2 ---
        seq_reg2 = reg2_seq::type_id::create("seq_reg2");
        seq_reg2.reg_block = reg_model; 
        seq_reg2.start(env.agent.seqr);

        // --- Start Sequence 4: REG3 ---
        seq_reg3 = reg3_seq::type_id::create("seq_reg3");
        seq_reg3.reg_block = reg_model; 
        seq_reg3.start(env.agent.seqr);

        // --- Start Sequence 5: REG4 ---
        seq_reg4 = reg4_seq::type_id::create("seq_reg4");
        seq_reg4.reg_block = reg_model; 
        seq_reg4.start(env.agent.seqr);

        `uvm_info("RUN TEST" , "ALL RAL SEQUENCES COMPLETED" , UVM_LOW)

      `ifdef COV_EN
          LOOP_COUNT = LOOP_COUNT +1;
        end
       `endif

        `uvm_info("RUN TEST", "APPLYING RESET (presetn = 0)", UVM_LOW)
        vif.presetn = 1'b0;
        repeat(5) @(posedge vif.pclk);   // hold reset for 5 clocks
        vif.presetn = 1'b1;
        repeat(2) @(posedge vif.pclk);   // 2 clocks settling time after release
        `uvm_info("RUN TEST", "RESET RELEASED (presetn = 1)", UVM_LOW)

      phase.drop_objection(this);
      //----------------------------------------------------------------------------------------  
    endtask

  endclass

endpackage
