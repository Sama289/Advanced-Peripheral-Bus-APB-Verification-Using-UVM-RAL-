package my_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import my_agent_pkg::* ;
  import apb_sequence_item_pkg::*;
  import my_scoreboard_pkg::*;
  import apb_reg_block_pkg::*;    // ADDED_FOR_RAL_INTEGRATION  
  import apb_adapter::*;      // ADDED_FOR_RAL_INTEGRATION 

  `define create(type , inst_name)  type::type_id::create(inst_name,this);  // CREATE() HERE REPLACES THE CONSTRUCTION LINE LARGE CODE LIKE A TEXT REPLACEMENT

  class my_env extends uvm_env;
    `uvm_component_utils(my_env)
    
    my_agent      agent;
    my_scoreboard sco;

    // ---- RAL Components ----
    top_reg_block reg_block;
    apb_adapter   adapter;



  //////////////
  /////////////  

    function new (string name = "my_env" , uvm_component parent = null);
       super.new(name , parent);
    endfunction



  //////////////
  ///////////// 

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
     `uvm_info("MY_ENV" , "ENVIRONMENT BUILT" , UVM_LOW);     

     agent = `create(my_agent,"agent");       //HERE WE USED THE MACRO INSTEAD OF LARGE CODE WHICH DEFINED ABOVE
     sco   = `create(my_scoreboard,"sco");

      //-------------- ADDED_FOR_RAL_INTEGRATION -------------

      // Build Adapter
      adapter    = `create(apb_adapter,"adapter");

       // Fetch the register block created in the test
       if(!uvm_config_db#(top_reg_block)::get(this, "", "reg_block", reg_block)) begin
         `uvm_fatal("MY_ENV", "Failed to get reg_block from config_db!")
       end

      //------------------------------------------------------

    endfunction




  //////////////
  ///////////// 

    function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
         agent.mon.mon_ap.connect(sco.sco_ap); //connected monitor in agent with sco_import


      //------- ADDED_FOR_RAL_INTEGRATION -------

       // ---- Set up Implicit Predictor ----
       reg_block.default_map.set_auto_predict(1);
       reg_block.default_map.set_sequencer(agent.seqr, adapter);  // connect seqr in this agent with adapter of map in reg_block

        `uvm_info("MY_ENV", "RAL model connected (implicit predictor)", UVM_LOW)      
      //--------------------------------------------
    endfunction
    
  endclass

endpackage

