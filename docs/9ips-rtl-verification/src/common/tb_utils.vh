
`ifndef TB_UTILS_VH
`define TB_UTILS_VH

`define TB_DECLARE                                                             \
  integer tb_checks  = 0;                                                      \
  integer tb_errors  = 0;                                                      \
  integer tb_verbose = 0;

`define CHECK_EQ(NAME, ACT, EXP)                                               \
  begin                                                                        \
    tb_checks = tb_checks + 1;                                                 \
    if ((ACT) !== (EXP)) begin                                                 \
      tb_errors = tb_errors + 1;                                               \
      $display("[%0t] ERROR %0s : got=0x%0h exp=0x%0h",                        \
               $time, NAME, ACT, EXP);                                         \
    end else if (tb_verbose) begin                                             \
      $display("[%0t] pass  %0s : 0x%0h", $time, NAME, ACT);                   \
    end                                                                        \
  end

`define CHECK_TRUE(NAME, COND)                                                 \
  begin                                                                        \
    tb_checks = tb_checks + 1;                                                 \
    if (!(COND)) begin                                                         \
      tb_errors = tb_errors + 1;                                               \
      $display("[%0t] ERROR %0s : condition failed", $time, NAME);             \
    end                                                                        \
  end

`define INFO(MSG)   $display("[%0t] INFO  %0s", $time, MSG);
`define DBG(MSG)    if (tb_verbose) $display("[%0t] DEBUG %0s", $time, MSG);

`define TB_BANNER(NAME)                                                        \
  begin                                                                        \
    $display("TEST START : %0s", NAME);                                        \
  end

`define TB_SUMMARY(NAME)                                                       \
  begin                                                                        \
    $display("TEST END: %0s", NAME);                                        \
    $display("checks run: %0d", tb_checks);                                   \
    $display("errors: %0d", tb_errors);                                   \
    if ((tb_errors == 0) && (tb_checks > 0))                                    \
      $display("RESULT: PASSED");                                 \
    else                                                                        \
      $display("RESULT: FAILED");                                 \
  end

`define TB_WATCHDOG(CLK, CYCLES)                                               \
  integer tb_wd_cnt = 0;                                                       \
  always @(posedge CLK) begin                                                  \
    tb_wd_cnt = tb_wd_cnt + 1;                                                 \
    if (tb_wd_cnt > CYCLES) begin                                              \
      $display("[%0t] ERROR watchdog expired after %0d cycles - HUNG",         \
               $time, CYCLES);                                                 \
      $display(" RESULT     : *** FAILED ***");                                 \
      $finish;                                                                 \
    end                                                                        \
  end

`define TB_DUMP(TOP, FNAME)                                                    \
  initial begin                                                                \
    `ifdef DUMP_VCD                                                            \
      $dumpfile(FNAME);                                                        \
      $dumpvars(0, TOP);                                                       \
    `endif                                                                     \
  end

`endif
