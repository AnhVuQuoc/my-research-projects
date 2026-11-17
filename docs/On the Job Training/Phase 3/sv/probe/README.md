# XSim feature probes

7 tiny tests, one SystemVerilog / UVM feature group each, to find out what a
simulator supports before porting a testbench to it.

| Probe | Feature | Needed by |
|---|---|---|
| p1_class | classes, inheritance, virtual methods, queues, associative arrays | any class-based testbench |
| p2_rand | `rand`, `constraint`, `dist`, `inside`, `randomize() with` | constrained random (tadc_cfg, adc_item) |
| p3_cov | `covergroup`, `coverpoint`, `bins`, `cross` | functional coverage with covergroups |
| p4_sva | concurrent assertions, `$past`, `disable iff`, `cover property` | sv/timer_adc_sva.sv |
| p5_vif | interface, virtual interface, mailbox, `fork ... join_none` | drivers and monitors |
| p6_bind | `bind` of a checker | sv/timer_adc_bind.sv |
| p7_uvm | UVM: sequence, driver, sequencer, phases (`-L uvm`) | tb/uvm |

Run in the Vivado Tcl Console: `source <path>/sv/probe/run_probes.tcl`

Reference on Verilator 5.020: p1, p5, p6 PASS; p2 and p3 unsupported; p4 hits a tool bug on the cover action.
