// =============================================================================
// File        : tb_irq_unit.v      Module: tb_irq_unit
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Part 1      : truth table: every combination of irq, id_valid, stall, branch,
//               halted, id_is_reti, id_is_wfi (128) for IE = 0/1 and sleeping =
//               0/1 (512 rows); take, reti_go, redirect, redirect_pc and sleep
//               are compared with the decision equations of the design sheet
// Part 2      : 20,000 random clocks against a sequential model of IE, EPC, the
//               shadow flags and the sleeping state
// =============================================================================
`timescale 1ns / 1ps
module tb_irq_unit;
    reg clk = 0, rst = 1, irq = 0, idv = 0, stall = 0, branch = 0, halted = 0, reti = 0, ei = 0, di = 0, wfi = 0, nz = 0, nc = 0;
    reg [7:0] idpc = 0, ifpc = 0;
    wire ie, take, reti_go, redirect, sleep, restore, sz, sc; wire [7:0] epc, rpc;
    always #5 clk = ~clk;
    irq_unit #(.VECTOR(8'h10)) DUT (.clk(clk), .rst(rst), .irq(irq), .id_valid(idv), .id_pc(idpc), .if_pc(ifpc), .stall(stall),
        .branch(branch), .halted(halted), .id_is_reti(reti), .id_is_ei(ei), .id_is_di(di), .id_is_wfi(wfi), .flag_next_z(nz),
        .flag_next_c(nc), .ie(ie), .epc(epc), .take(take), .reti_go(reti_go), .redirect(redirect), .redirect_pc(rpc), .sleep(sleep),
        .restore(restore), .sz(sz), .sc(sc));
    integer errors = 0, checks = 0, k, seed = 32'h5E203519, c_take = 0, c_tsleep = 0, c_reti = 0;
    reg m_ie, m_sl, e_take, e_reti, e_sleep, e_ts, e_tr, e_wfi; reg [7:0] m_epc; reg m_sz, m_sc;
    task expect_now; begin            // the decision equations, written from the design sheet
        e_ts = m_sl & irq & m_ie;
        e_tr = ~m_sl & ~halted & irq & m_ie & idv & ~stall & ~branch & ~reti;
        e_take = e_ts | e_tr; e_reti = reti & idv & ~stall;
        e_wfi = wfi & idv & ~stall & ~e_tr & ~irq; e_sleep = e_wfi | (m_sl & ~irq);
    end endtask
    task compare; begin checks = checks + 1;
        if (take !== e_take || reti_go !== e_reti || redirect !== (e_take | e_reti) || sleep !== e_sleep || restore !== e_reti ||
            rpc !== (e_take ? 8'h10 : m_epc) || ie !== m_ie || epc !== m_epc || sz !== m_sz || sc !== m_sc) begin
            errors = errors + 1; if (errors < 10) $display("  FAIL t=%0t take %b/%b reti %b/%b sleep %b/%b ie %b/%b epc %h/%h", $time, take, e_take, reti_go, e_reti, sleep, e_sleep, ie, m_ie, epc, m_epc); end
    end endtask
    task model_edge; begin
        if (e_take) begin m_ie = 0; m_epc = e_ts ? ifpc : idpc; m_sz = nz; m_sc = nc; end
        else if (e_reti) m_ie = 1; else if (ei & idv & ~stall) m_ie = 1; else if (di & idv & ~stall) m_ie = 0;
        if (e_take | (m_sl & irq)) m_sl = 0; else if (e_wfi) m_sl = 1;
    end endtask
    integer v, s, ieq; reg [6:0] combo;
    initial begin
        $display("============================================================================");
        $display(" tb_irq_unit : interrupt entry, RETI, EI, DI, WFI");
        $display(" Student: Vu Quoc Anh | Roll number: SE203519");
        $display("============================================================================");
        m_ie = 0; m_sl = 0; m_epc = 0; m_sz = 0; m_sc = 0;
        @(negedge clk); rst = 0;
        $display("PART 1: truth table, 128 input combinations x IE x sleeping = 512 rows");
        $display("  irq idv stall br halt reti wfi | IE sl | take reti_go sleep");
        for (ieq = 0; ieq < 4; ieq = ieq + 1) for (v = 0; v < 128; v = v + 1) begin
            @(negedge clk); DUT.ie = ieq[0]; DUT.sleeping = ieq[1]; m_ie = ieq[0]; m_sl = ieq[1]; DUT.epc = 8'h3C; m_epc = 8'h3C;
            combo = v; {irq, idv, stall, branch, halted, reti, wfi} = combo; ei = 0; di = 0; idpc = 8'h25; ifpc = 8'h27;
            #1 expect_now; compare;
            if (v == 7'b1100000 || v == 7'b1110000 || v == 7'b0100001 || v == 7'b1000000 || v == 7'b0100100)
                $display("   %b   %b    %b    %b   %b    %b    %b  |  %b  %b |  %b      %b       %b", irq, idv, stall, branch, halted, reti, wfi, m_ie, m_sl, take, reti_go, sleep);
        end
        {irq, idv, stall, branch, halted, reti, wfi} = 0;
        @(negedge clk); rst = 1; @(negedge clk); rst = 0; m_ie = 0; m_sl = 0; m_epc = 0; m_sz = 0; m_sc = 0;
        $display("PART 2: 20,000 random clocks against the sequential model");
        for (k = 0; k < 20000; k = k + 1) begin
            @(negedge clk);
            irq = ($unsigned($random(seed)) % 3) == 0; idv = ($unsigned($random(seed)) % 5) != 0; stall = ($unsigned($random(seed)) % 6) == 0;
            branch = ($unsigned($random(seed)) % 8) == 0; halted = ($unsigned($random(seed)) % 200) == 0;
            s = $unsigned($random(seed)) % 20; reti = (s == 0); ei = (s == 1) | (s == 2); di = (s == 3); wfi = (s == 4);
            idpc = $random(seed); ifpc = $random(seed); nz = $random(seed); nc = $random(seed);
            #1 expect_now; compare; if (e_tr) c_take = c_take + 1; if (e_ts) c_tsleep = c_tsleep + 1; if (e_reti) c_reti = c_reti + 1;
            @(posedge clk); model_edge;
        end
        $display("  coverage: takes while running %0d, takes from sleep %0d, RETI %0d", c_take, c_tsleep, c_reti);
        #1;
        if (errors == 0) $display("PASS: tb_irq_unit (Vu Quoc Anh, SE203519) 512 truth-table rows + 20000 random clocks, %0d checks, 0 errors", checks);
        else $display("FAILED: tb_irq_unit (Vu Quoc Anh, SE203519) %0d errors", errors);
        $finish(0);
    end
endmodule
