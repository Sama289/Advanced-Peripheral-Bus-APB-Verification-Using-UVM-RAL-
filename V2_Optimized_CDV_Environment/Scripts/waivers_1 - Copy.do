
# SECTION 1 — TOGGLE : paddr Lower Bits [0:1]

# 1a. Waive paddr[0:1] on the interface
#     APB is a word-aligned bus (32-bit data, no byte strobes).
#     Address bits [1:0] are permanently 0 by protocol definition
#     and will never toggle in this design.
coverage exclude -du APB_If -toggle {paddr[0:1]}

# 1b. Same waiver on the DUT input port
coverage exclude -du APB -toggle {paddr[0:1]}


# SECTION 2 — TOGGLE : paddr Upper Bits [5:31]

# 2a. Waive paddr[5:31] on the interface
#     The register map contains only 5 registers at addresses
#     0x00, 0x04, 0x08, 0x0C, 0x10.  Bit[4] is the highest address bit ever driven (addr=0x10)
#     Bits[5:31] are structurally unreachable for this register map.   
coverage exclude -du APB_If -toggle {paddr[5:31]}

# 2b. Same waiver on the DUT input port
coverage exclude -du APB -toggle {paddr[5:31]}


# SECTION 3 — BRANCH : Write-CASE "All False" (line 39)

# 3. Waive the All-False path of the write CASE statement (line 39)
# RAL never writes to an unmapped address
coverage exclude -srcfile APB.sv -line 39 -item b 6


# SECTION 4 — BRANCH + STATEMENT : Read-CASE default (line 55)

# 4a. Waive the default CASE arm branch at line 55
#     RAL never reads from an unmapped address
coverage exclude -srcfile APB.sv -line 55 -item b 1

# 4b. Waive the default CASE statement at line 55
coverage exclude -src APB.sv -line 55 -code s


# SECTION 5 — FEC CONDITION : pwrite=1 masked at line 47 (Row 6)

# 5. Waive FEC row 6 for the condition at line 47
#  on line 47 can never be evaluated — line 37 catches it first
coverage exclude -srcfile APB.sv -feccondrow 47 6
