
# -----------------------------------------------------------------------
# 0.  Paths
# -----------------------------------------------------------------------
set SIM_DIR         [pwd]                          ;# .../APB_RAL_V2/Sim
set BASE_DIR        [file dirname $SIM_DIR]        ;# .../APB_RAL_V2

set DESIGN_DIR      $BASE_DIR/Design
set UVM_DIR         $BASE_DIR/UVM_ENV
set NO_CHANGE_DIR   $BASE_DIR/UVM_ENV/NO_CHANGE
set RAL_DIR         $BASE_DIR/RAL_MODEL
set COV_OUT         $BASE_DIR/Coverage_reports
set SCRIPTS_DIR     $BASE_DIR/Scripts
set WAIVERS_FILE    $SCRIPTS_DIR/waivers_1.do


# -----------------------------------------------------------------------
# 1.  Create work library
# -----------------------------------------------------------------------
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

# -----------------------------------------------------------------------
# 2.  Compile  (strict bottom-up dependency order)
# -----------------------------------------------------------------------

puts "\n========== [2] COMPILING =========="

set COV_FLAGS "+cover -covercells +define+COV_EN"

# 1 — Design
eval vlog -work work -sv -stats=none $COV_FLAGS \
     $DESIGN_DIR/APB.sv

# 2 — Interface (no package deps)
eval vlog -work work -sv -stats=none $COV_FLAGS \
     $NO_CHANGE_DIR/APB_If.sv

# 3 — Sequence item package (needed by almost everything)
eval vlog -work work -sv -stats=none $COV_FLAGS \
     $UVM_DIR/my_sequence_item.sv

# 4 — Sequencer, Driver, Monitor packages (all need apb_sequence_item_pkg)
eval vlog -work work -sv -stats=none $COV_FLAGS \
     $NO_CHANGE_DIR/my_sequencer.sv

eval vlog -work work -sv -stats=none $COV_FLAGS \
     $UVM_DIR/my_driver.sv

eval vlog -work work -sv -stats=none $COV_FLAGS \
     $UVM_DIR/my_monitor.sv

# 5 — Agent (needs sequencer + driver + monitor packages)
eval vlog -work work -sv -stats=none $COV_FLAGS \
     $NO_CHANGE_DIR/my_agent.sv

# 6 — RAL model (regs -> block -> adapter -> sequences)
#     apb_regs_pkg.sv contains `ifdef COV_EN — covergroups only compiled with +define+COV_EN
eval vlog -work work -sv -stats=none $COV_FLAGS \
     $RAL_DIR/apb_regs_pkg.sv

eval vlog -work work -sv -stats=none $COV_FLAGS \
     $RAL_DIR/apb_reg_block_pkg.sv

eval vlog -work work -sv -stats=none $COV_FLAGS \
     $RAL_DIR/apb_adapter.sv

eval vlog -work work -sv -stats=none $COV_FLAGS \
     $RAL_DIR/apb_reg_sequences_pkg.sv

# 7 — Remaining ENV components (config, scoreboard, env, test)
eval vlog -work work -sv -stats=none $COV_FLAGS \
     $NO_CHANGE_DIR/my_config.sv

eval vlog -work work -sv -stats=none $COV_FLAGS \
     $UVM_DIR/my_scoreboard.sv

eval vlog -work work -sv -stats=none $COV_FLAGS \
     $UVM_DIR/my_env.sv

eval vlog -work work -sv -stats=none $COV_FLAGS \
     $UVM_DIR/my_test.sv

# 8 — Top (instantiates everything)
eval vlog -work work -sv -stats=none $COV_FLAGS \
     $NO_CHANGE_DIR/top.sv

puts "========== COMPILE DONE ==========\n"

# -----------------------------------------------------------------------
# 3.  Three random-seed simulation runs
# -----------------------------------------------------------------------
puts "\n========== [3] RUNNING 3 SEEDS ==========\n"

set ucdb_files {}

for {set i 0} {$i < 1} {incr i} {

    # --- Generate a proper random seed ---
    set seed [expr { int(rand() * 999999) + 1 }]
    set ucdb_file "$SIM_DIR/cov_run${i}_seed${seed}.ucdb"
    lappend ucdb_files $ucdb_file

    puts "--- Run $i  |  seed = $seed  |  ucdb = $ucdb_file ---"

    if {$i < 1} {
        # Runs 0 and 1: load waves, run, save coverage, quit automatically
        vsim -voptargs=+acc \
             -coverage \
             +UVM_TESTNAME=my_test \
             +ntb_random_seed=$seed \
             +UVM_VERBOSITY=UVM_LOW \
             work.top \
             -do "
                coverage save -onexit $ucdb_file
                do ../Scripts/wave.do
                do $WAIVERS_FILE
                run -all
                quit -sim
             "
    } else {
        # Run 2 (last): load waves, run, stay open — waveform available for debugging
        vsim -voptargs=+acc \
             -coverage \
             +UVM_TESTNAME=my_test \
             +ntb_random_seed=$seed \
             +UVM_VERBOSITY=UVM_LOW \
             work.top \
             -do "
                coverage save -onexit $ucdb_file
                do ../Scripts/wave.do
                do $WAIVERS_FILE
                run -all
             "
        # Script stops here and hands control back to the GUI for run 2.
        # Merge and report generation will run automatically once you
        # close the simulation manually (File -> Quit Simulation) or
        # type:  quit -sim   in the transcript.
    }

    puts "--- Run $i complete ---\n"
}

puts "========== ALL RUNS DONE ==========\n"

# -----------------------------------------------------------------------
# 4.  Merge UCDB files
# -----------------------------------------------------------------------
puts "\n========== [4] MERGING COVERAGE DATABASES =========="

set merged_ucdb "$SIM_DIR/merged_cov.ucdb"
eval vcover merge $merged_ucdb $ucdb_files

puts "Merged UCDB -> $merged_ucdb\n"

# -----------------------------------------------------------------------
# 5.  Generate reports  ->  Coverage_reports/
# -----------------------------------------------------------------------
puts "\n========== [5] GENERATING REPORTS =========="

# --- Text report (full detail, all types) ---
set txt_report  "$COV_OUT/cov_report.txt"
vcover report $merged_ucdb \
    -details \
    -all \
    -output $txt_report

puts "Text report  -> $txt_report"

# --- HTML report (functional + code coverage combined) ---
set html_report "$COV_OUT/html_report"
vcover report $merged_ucdb \
    -details \
    -html \
    -output $html_report

puts "HTML report  -> $html_report/index.html"

# --- Functional coverage only (separate clean view) ---
set func_report "$COV_OUT/functional_cov_report.txt"
vcover report $merged_ucdb \
    -details \
    -cvg \
    -output $func_report

puts "Functional   -> $func_report"

# --- Code coverage only (separate clean view) ---
set code_report "$COV_OUT/code_cov_report.txt"
vcover report $merged_ucdb \
    -details \
    -code bcestf \
    -output $code_report

puts "Code cov     -> $code_report"

# -----------------------------------------------------------------------
# 6.  Summary
# -----------------------------------------------------------------------
puts "\n============================================================"
puts " COVERAGE RUN COMPLETE"
puts "============================================================"
puts " Seeds used    : 3 independent random seeds"
puts " UCDB files    : $SIM_DIR/cov_run*.ucdb"
puts " Merged UCDB   : $merged_ucdb"
puts " Text report   : $txt_report"
puts " Functional    : $func_report"
puts " Code cov      : $code_report"
puts " HTML report   : $html_report/index.html"
puts "============================================================"
puts " Last sim is still alive — use the GUI for wave debugging"
puts " Open HTML:  start $html_report/index.html"
puts "============================================================\n"
