`timescale 1ns / 1ps
// ============================================================================
// tb_muldiv_unit.v : self checking testbench for muldiv_unit
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// muldiv_unit has no adder of its own, so this bench connects it directly to
// an adder_subtractor_4bit (in the real ALU the same adder is reached through
// the busy controlled muxes in alu_4bit.v).
// Part 1  : step tables, register values after every rising edge, for
//           MUL 13 x 11, DIV 13 / 4 and DIV 9 / 0 (time stamps match the
//           waveform; the clock period is 10 ns).
// Part 2  : self checks: reset state, all 256 (a, b) pairs for MUL and for
//           DIV with latency and busy length, protocol tests (start held
//           high, inputs changed while busy, result held, asynchronous reset
//           in the middle of an operation) and the r_top monitor.
// Ends with one PASS or FAILED line.
// ============================================================================
module tb_muldiv_unit;
    reg        clk = 0, rst = 1, start = 0, is_div = 0;
    reg  [3:0] a = 0, b = 0;
    wire [3:0] add_a, add_b, add_sum, hi, lo;
    wire       add_sub, add_c3, add_c4, busy, done, div_by_zero;

    muldiv_unit dut (
        .clk(clk), .rst(rst), .start(start), .is_div(is_div), .a(a), .b(b),
        .add_a(add_a), .add_b(add_b), .add_sub(add_sub),
        .add_sum(add_sum), .add_c4(add_c4),
        .hi(hi), .lo(lo), .busy(busy), .done(done), .div_by_zero(div_by_zero)
    );
    adder_subtractor_4bit u_add (
        .a(add_a), .b(add_b), .sub(add_sub), .sum(add_sum), .c3(add_c3), .c4(add_c4)
    );

    always #5 clk = ~clk;                 // 10 ns period

    // r_top monitor: count DIV steps in which the bit shifted out of acc
    // (r_top = acc[3]) is 1. With a 4 bit dividend it is always 0.
    integer div_steps = 0, rtop_hits = 0;
    always @(posedge clk)
        if (!rst && dut.running && dut.mode_div) begin
            div_steps = div_steps + 1;
            if (dut.r_top) rtop_hits = rtop_hits + 1;
        end

    integer errors, i, cycles, busy_cycles, k;
    reg [7:0] ab;
    reg [7:0] held;

    // Drive at the falling edge, the DUT samples at the rising edge.
    // cycles      = rising edges from the load edge until done = 1 (expect 5)
    // busy_cycles = number of sampled clocks with busy = 1          (expect 4)
    task run(input div, input [3:0] x, input [3:0] y);
        begin
            @(negedge clk);
            is_div = div; a = x; b = y; start = 1;
            @(negedge clk);                // load edge has happened
            start = 0; cycles = 1; busy_cycles = 0;
            while (!done) begin
                if (busy) busy_cycles = busy_cycles + 1;
                @(negedge clk); cycles = cycles + 1;
                if (cycles > 20) begin $display("  FAIL timeout"); errors = errors + 1; disable run; end
            end
        end
    endtask

    task trace(input div, input [3:0] x, input [3:0] y);
        begin
            @(negedge clk);
            is_div = div; a = x; b = y; start = 1;
            @(negedge clk); start = 0;
            $display("  %4d ns | load   |  %0d    | %b | %b | %b   %b   %b",
                     $time - 5, dut.count, hi, lo, dut.m, busy, done);
            k = 1;
            while (!done) begin
                @(negedge clk);
                $display("  %4d ns | step %0d |  %0d    | %b | %b |        %b   %b",
                         $time - 5, k, dut.count, hi, lo, busy, done);
                k = k + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_muldiv_unit");
        $display("============================================================");
        #12 rst = 0;

        $display("Part 1: step tables (values after each rising edge)");
        $display("  MUL 13 x 11 (expect {acc, q} = 1000 1111 = 143)");
        $display("  edge    | clock  | count | acc  | q    | m    busy done");
        trace(0, 13, 11);
        if ({hi, lo} !== 8'd143) begin errors = errors + 1; $display("  FAIL 13x11"); end
        $display("  DIV 13 / 4 (expect quotient q = 0011, remainder acc = 0001)");
        $display("  edge    | clock  | count | acc  | q    | m    busy done");
        trace(1, 13, 4);
        if (lo !== 4'd3 || hi !== 4'd1) begin errors = errors + 1; $display("  FAIL 13/4"); end
        $display("  DIV 9 / 0 (expect q = 1111, acc = 1001, div_by_zero = 1)");
        $display("  edge    | clock  | count | acc  | q    | m    busy done");
        trace(1, 9, 0);
        if (lo !== 4'b1111 || hi !== 4'd9 || div_by_zero !== 1) begin errors = errors + 1; $display("  FAIL 9/0"); end

        $display("Part 2: self checks");
        // ---------------- reset state ----------------
        @(negedge clk); #1 rst = 1; #1;
        if (busy !== 0 || done !== 0 || hi !== 0 || lo !== 0 || div_by_zero !== 0) begin
            errors = errors + 1; $display("  FAIL reset state");
        end
        #3 rst = 0;
        $display("  reset state checked");

        // ---------------- Test 3: exhaustive ----------------
        for (i = 0; i < 256; i = i + 1) begin
            ab = i;
            run(0, ab[7:4], ab[3:0]);
            if ({hi, lo} !== ab[7:4] * ab[3:0] || cycles != 5 || busy_cycles != 4 || div_by_zero !== 0) begin
                errors = errors + 1;
                if (errors <= 10) $display("  FAIL MUL %0d*%0d got %0d, %0d cycles, busy %0d",
                                           ab[7:4], ab[3:0], {hi, lo}, cycles, busy_cycles);
            end
            run(1, ab[7:4], ab[3:0]);
            if (ab[3:0] == 0) begin
                if (div_by_zero !== 1 || lo !== 4'b1111 || hi !== ab[7:4]) begin
                    errors = errors + 1;
                    if (errors <= 10) $display("  FAIL DIV %0d/0", ab[7:4]);
                end
            end
            else if (lo !== ab[7:4] / ab[3:0] || hi !== ab[7:4] % ab[3:0] ||
                     div_by_zero !== 0 || cycles != 5 || busy_cycles != 4) begin
                errors = errors + 1;
                if (errors <= 10) $display("  FAIL DIV %0d/%0d got q=%0d r=%0d", ab[7:4], ab[3:0], lo, hi);
            end
        end
        $display("  exhaustive MUL and DIV (512 operations) checked, errors so far = %0d", errors);

        // ---------------- Test 4: protocol ----------------
        // 4a: start held high for 3 clocks -> must not restart while running
        @(negedge clk); is_div = 0; a = 7; b = 6; start = 1;
        repeat (3) @(negedge clk);
        start = 0;
        while (!done) @(negedge clk);
        if ({hi, lo} !== 8'd42) begin errors = errors + 1; $display("  FAIL start-held: got %0d", {hi, lo}); end

        // 4b: change a, b while busy -> result must use the values from the load edge
        @(negedge clk); is_div = 0; a = 9; b = 5; start = 1;
        @(negedge clk); start = 0; a = 15; b = 15; is_div = 1;
        while (!done) @(negedge clk);
        if ({hi, lo} !== 8'd45) begin errors = errors + 1; $display("  FAIL inputs-changed: got %0d", {hi, lo}); end

        // 4c: result and done held for 10 clocks after done
        held = {hi, lo};
        repeat (10) begin
            @(negedge clk);
            if ({hi, lo} !== held || done !== 1 || busy !== 0) begin
                errors = errors + 1; $display("  FAIL result not held");
            end
        end

        // 4d: asynchronous reset in the middle of an operation
        @(negedge clk); is_div = 0; a = 11; b = 13; start = 1;
        @(negedge clk); start = 0;
        @(negedge clk); #2 rst = 1; #1;                 // not on a clock edge
        if (busy !== 0 || done !== 0 || hi !== 0 || lo !== 0) begin
            errors = errors + 1; $display("  FAIL async reset");
        end
        #5 rst = 0;
        run(0, 11, 13);
        if ({hi, lo} !== 8'd143) begin errors = errors + 1; $display("  FAIL after reset"); end

        $display("  protocol checks done (start held, inputs changed, result held, async reset)");
        $display("  info: r_top was 1 in %0d of %0d DIV steps", rtop_hits, div_steps);
        if (errors == 0) $display("PASS: tb_muldiv_unit (Vu Quoc Anh, SE203519), step tables + 512 exhaustive + protocol, 0 errors");
        else             $display("FAILED: tb_muldiv_unit, %0d errors", errors);
        $finish;
    end
endmodule
