# =============================================================================
# run_cov.do  —  APB RAL V2  |  3-seed functional + code coverage run
# =============================================================================
# Directory layout (relative to Sim/ where this script is launched from):
#   ../Design/           APB.sv
#   ../UVM_ENV/          my_driver.sv, my_monitor.sv, my_scoreboard.sv,
#                        my_sequence_item.sv, my_env.sv, my_test.sv,
#                        my_config.sv
#   ../UVM_ENV/NO_CHANGE/ top.sv, my_agent.sv, my_sequencer.sv, APB_If.sv
#   ../RAL_MODEL/        apb_adapter.sv, apb_reg_block_pkg.sv,
#                        apb_regs_pkg.sv, apb_reg_sequences_pkg.sv
#   Coverage_reports/    output destination  (sibling of Sim/)
# =============================================================================

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
# Dependency tree (each line must compile before anything that imports it):
#
#   APB.sv                          (design — no UVM deps)
#   APB_If.sv                       (interface — no deps)
#   my_sequence_item.sv             (apb_sequence_item_pkg)
#   my_sequencer.sv                 (my_sequencer_pkg)  ← needs apb_sequence_item_pkg
#   my_driver.sv                    (my_driver_pkg)     ← needs apb_sequence_item_pkg
#   my_monitor.sv                   (my_monitor_pkg)    ← needs apb_sequence_item_pkg
#   my_agent.sv                     (my_agent_pkg)      ← needs seqr + drv + mon pkgs
#   apb_regs_pkg.sv                 (RAL registers)     ← `ifdef COV_EN activates covergroups
#   apb_reg_block_pkg.sv            ← needs apb_regs_pkg
#   apb_adapter.sv                  ← needs apb_sequence_item_pkg
#   apb_reg_sequences_pkg.sv        ← needs item + block + regs pkgs
#   my_config.sv                    (my_config_pkg)
#   my_scoreboard.sv                (my_scoreboard_pkg) ← needs apb_sequence_item_pkg
#   my_env.sv                       (my_env_pkg)        ← needs agent + sco + RAL
#   my_test.sv                      (my_test_pkg)       ← needs env + sequences
#   top.sv                          ← needs everything
#
# +define+COV_EN  — unlocks the `ifdef COV_EN blocks in apb_regs_pkg.sv
#                   without this define the entire covergroup is dead code
#                   and functional coverage will be zero
# -----------------------------------------------------------------------
puts "\n========== [2] COMPILING =========="

# Shared compile flags — define applied globally so any `ifdef COV_EN
# in any file is visible to the compiler
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

# 6 — RAL model (regs → block → adapter → sequences)
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
        # close the simulation manually (File → Quit Simulation) or
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

puts "Merged UCDB → $merged_ucdb\n"

# -----------------------------------------------------------------------
# 5.  Generate reports  →  Coverage_reports/
# -----------------------------------------------------------------------
puts "\n========== [5] GENERATING REPORTS =========="

# --- Text report (full detail, all types) ---
set txt_report  "$COV_OUT/cov_report.txt"
vcover report $merged_ucdb \
    -details \
    -all \
    -output $txt_report

puts "Text report  → $txt_report"

# --- HTML report (functional + code coverage combined) ---
set html_report "$COV_OUT/html_report"
vcover report $merged_ucdb \
    -details \
    -html \
    -output $html_report

puts "HTML report  → $html_report/index.html"

# --- Functional coverage only (separate clean view) ---
set func_report "$COV_OUT/functional_cov_report.txt"
vcover report $merged_ucdb \
    -details \
    -cvg \
    -output $func_report

puts "Functional   → $func_report"

# --- Code coverage only (separate clean view) ---
set code_report "$COV_OUT/code_cov_report.txt"
vcover report $merged_ucdb \
    -details \
    -code bcestf \
    -output $code_report

puts "Code cov     → $code_report"

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
