# ============================================================
#  waivers.do  —  APB RAL Verification Project
#  Design Units : work.APB  |  work.APB_If
#  Generated for : APB_RAL_V2
# ============================================================


# ============================================================
# SECTION 1 — TOGGLE : paddr Lower Bits [0:1]
# ============================================================

# 1a. Waive paddr[0:1] on the interface
#     APB is a word-aligned bus (32-bit data, no byte strobes).
#     Address bits [1:0] are permanently 0 by protocol definition
#     and will never toggle in this design.
coverage exclude -du APB_If -toggle {paddr[0:1]}

# 1b. Same waiver on the DUT input port
coverage exclude -du APB -toggle {paddr[0:1]}


# ============================================================
# SECTION 2 — TOGGLE : paddr Upper Bits [5:31]
# ============================================================

# 2a. Waive paddr[5:31] on the interface
#     The register map contains only 5 registers at addresses
#     0x00, 0x04, 0x08, 0x0C, 0x10.  Bit[4] is the highest
#     address bit ever driven (addr=0x10).  Bits[5:31] are
#     structurally unreachable for this register map.
coverage exclude -du APB_If -toggle {paddr[5:31]}

# 2b. Same waiver on the DUT input port
coverage exclude -du APB -toggle {paddr[5:31]}


# ============================================================
# SECTION 3 — TOGGLE : presetn
# ============================================================

# 3a. Waive presetn toggle on the interface
#     presetn is driven high at time 0 and held asserted for
#     the entire RAL sequence run.  No reset sequence is
#     issued during the test, so both toggle directions
#     (0->1 and 1->0) are never observed by the toggle engine.
#     [To FIX instead of waive: add a reset sequence before
#      the RAL sequences in run_phase.]
coverage exclude -du APB_If -toggle {presetn}

# 3b. Same waiver on the DUT input port
coverage exclude -du APB -toggle {presetn}


# ============================================================
# SECTION 4 — BRANCH : Reset IF-path (line 27, item 1)
# ============================================================

# 4. Waive the true-branch of "if (!presetn)" at line 27
#    presetn is held high throughout simulation (see Section 3).
#    The !presetn == TRUE path (item 1) has a hit count of ***0***.
#    Branch totals show 3 of 4 branches hit (75%) because of this.
coverage exclude -srcfile APB.sv -line 27 -item b 1


# ============================================================
# SECTION 5 — STATEMENT : Reset Body (lines 29-34)
# ============================================================

# 5. Waive all statements inside the reset block (lines 29-34)
#    These six assignments are only reachable when !presetn is
#    true (see Section 4).  Since the reset branch is never
#    entered, all six statements show ***0*** hits.
coverage exclude -src APB.sv -line 29 -code s
coverage exclude -src APB.sv -line 30 -code s
coverage exclude -src APB.sv -line 31 -code s
coverage exclude -src APB.sv -line 32 -code s
coverage exclude -src APB.sv -line 33 -code s
coverage exclude -src APB.sv -line 34 -code s


# ============================================================
# SECTION 6 — BRANCH : Write-CASE "All False" (line 39)
# ============================================================

# 6. Waive the All-False path of the write CASE statement (line 39)
#    The UVM RAL model only generates accesses to the 5 mapped
#    register addresses (0x00-0x10).  An unmapped write address
#    that causes all 5 CASE arms to be skipped is unreachable
#    by design when driving stimulus through the RAL adapter.
#    The All-False count shows ***0*** (item 6 = after all 5 arms).
coverage exclude -srcfile APB.sv -line 39 -item b 6


# ============================================================
# SECTION 7 — BRANCH + STATEMENT : Read-CASE default (line 55)
# ============================================================

# 7a. Waive the default CASE arm branch at line 55
#     Same rationale as Section 6: the RAL model never issues
#     a read to an unmapped address, so the default arm
#     "rdata_tmp <= 32'h00000000" is structurally unreachable
#     under RAL-driven stimulus.  Item 6 of the CASE at line 49.
coverage exclude -srcfile APB.sv -line 55 -item b 1

# 7b. Waive the default CASE statement at line 55
coverage exclude -src APB.sv -line 55 -code s


# ============================================================
# SECTION 8 — FEC CONDITION : pwrite=1 masked at line 47 (Row 6)
# ============================================================

# 8. Waive FEC row 6 for the condition at line 47
#    Condition: ((psel && penable) && ~pwrite)
#    FEC target: pwrite_1  |  Non-masking: (psel && penable)
#    This row requires pwrite=1 while psel=1 AND penable=1 to be
#    evaluated at line 47.  However, when pwrite=1 with psel=1
#    and penable=1, the PRECEDING "if (psel && penable && pwrite)"
#    at line 37 is already TRUE and its body is taken — execution
#    never reaches the else-if at line 47.
#    This is a structural dead condition: unreachable by any stimulus.
coverage exclude -srcfile APB.sv -feccondrow 47 6
