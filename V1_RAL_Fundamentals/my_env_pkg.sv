package my_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import my_agent_pkg::*;
  import my_sequence_item_pkg::*;
  import my_scoreboard_pkg::*;
  import my_ral_pkg::*;
  import apb_reg_block_pkg::*;

  `define create(type , inst_name)  type::type_id::create(inst_name,this);

  class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    my_agent      agent;
    my_scoreboard sco;

    // ---- RAL Components ----
    apb_reg_block reg_block;
    apb_adapter   adapter;

    function new (string name = "my_env" , uvm_component parent = null);
       super.new(name , parent);
    endfunction

    function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       `uvm_info("MY_ENV" , "ENVIRONMENT BUILT" , UVM_LOW);     

       agent = `create(my_agent,"agent");
       sco   = `create(my_scoreboard,"sco");

       // Build the adapter
       adapter = apb_adapter::type_id::create("adapter");

       // Fetch the register block created in the test
       if(!uvm_config_db#(apb_reg_block)::get(this, "", "reg_block", reg_block)) begin
         `uvm_fatal("MY_ENV", "Failed to get reg_block from config_db!")
       end
    endfunction

    function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       agent.mon.mon_ap.connect(sco.sco_ap);

       // ---- Set up Implicit Predictor ----
       reg_block.default_map.set_auto_predict(1);
       reg_block.default_map.set_sequencer(agent.seqr, adapter);
    endfunction
    
  endclass

endpackage