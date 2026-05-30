# 1. Create work library
vlib work

# 2. Compile Design and Interface (No dependencies)
vlog APB.sv
vlog APB_If.sv

# 3. Compile Base Sequence Item
vlog my_sequence_item_pkg.sv

# 4. Compile RAL Model (This pulls in adapter and reg_block automatically 3shan el includes)
vlog my_ral_pkg.sv

# 5. Compile Sequences 
vlog my_reg_sequences_pkg.sv

# 6. Compile Agent Components 
vlog my_sequencer.sv
vlog my_driver.sv
vlog my_monitor.sv
vlog my_agent.sv

# 7. Compile Scoreboard
vlog my_scoreboard.sv

# 8. Compile Environment 
vlog my_env_pkg.sv

# 9. Compile Test 
vlog my_test_pkg.sv

# 10. Compile Top-level Testbench
vlog top.sv

# 11. Load the simulation with UVM 
vsim -voptargs=+acc work.top +UVM_TESTNAME=my_test

# 12. Add waves and run
do wave.do
run -all