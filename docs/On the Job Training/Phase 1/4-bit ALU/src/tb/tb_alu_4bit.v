`timescale 1ns / 1ps
// ============================================================================
// tb_alu_4bit.v : system testbench for the top level alu_4bit
// Student : Vu Quoc Anh   Roll number : SE203519
// Project : ALU4, a 4 bit ALU with shift based multiply and divide
// Part 1  : example table, 15 directed operations (single cycle rows 10 ns
//           apart, then MUL/DIV runs), printed with result and flags.
// Part 2  : self checks of the whole ALU
//           2a every single cycle opcode (14, including the 6 unused codes)
//              x 256 (a, b) = 3,584 cases: result, C, Z, V, N, busy, dbz
//           2b MUL and DIV x 256 = 512 cases: result, all flags,
//              div_by_zero and latency = 5 clocks
//           2c protocol: start ignored for single cycle opcodes, adder
//              returned after MUL, div_by_zero gated by opcode, reset
// Ends with one PASS or FAILED line.
// HOW TO RUN IN VIVADO: set as simulation top, Run Behavioral Simulation,
// then Run All (the default 1000 ns stop is too short; this bench needs
// about 35 us). The printed lines appear in the Tcl Console.
// ============================================================================
module tb_alu_4bit;
    reg        clk = 0, rst = 1, start = 0;
    reg  [3:0] a = 0, b = 0, opcode = 0;
    wire [7:0] result;
    wire       carry, zero, overflow, negative, div_by_zero, busy, done;

    alu_4bit dut (
        .clk(clk), .rst(rst), .start(start), .a(a), .b(b), .opcode(opcode),
        .result(result), .carry(carry), .zero(zero), .overflow(overflow),
        .negative(negative), .div_by_zero(div_by_zero), .busy(busy), .done(done)
    );

    always #5 clk = ~clk;                 // 100 MHz

    // ---------------- reference model for single-cycle opcodes ----------------
    reg [3:0] exp_r;
    reg       exp_c, exp_v;
    reg [4:0] t;
    task model;
        begin
            exp_c = 0; exp_v = 0; exp_r = 0;
            case (opcode)
                4'b0000: begin t = {1'b0, a} + {1'b0, b};        exp_r = t[3:0]; exp_c = t[4];
                               exp_v = (a[3] == b[3]) && (exp_r[3] != a[3]); end
                4'b0001: begin t = {1'b0, a} + {1'b0, ~b} + 5'd1; exp_r = t[3:0]; exp_c = t[4];
                               exp_v = (a[3] != b[3]) && (exp_r[3] != a[3]); end
                4'b0010: exp_r = a & b;
                4'b0011: exp_r = a | b;
                4'b0100: exp_r = a ^ b;
                4'b0101: exp_r = ~a;
                4'b0110: begin exp_r = {a[2:0], 1'b0}; exp_c = a[3]; end
                4'b0111: begin exp_r = {1'b0, a[3:1]}; exp_c = a[0]; end
                default: exp_r = 0;
            endcase
        end
    endtask

    // ---------------- run one MUL/DIV, count clocks (load edge = 1) ----------------
    integer cycles;
    task run_md(input [3:0] op, input [3:0] x, input [3:0] y);
        begin
            @(negedge clk);
            opcode = op; a = x; b = y; start = 1;
            @(negedge clk);
            start = 0; cycles = 1;
            while (!done) begin @(negedge clk); cycles = cycles + 1; end
        end
    endtask

    task show_comb(input [3:0] op, input [3:0] x, input [3:0] y, input [8*4-1:0] name);
        begin
            opcode = op; a = x; b = y; #10;
            $display("  %5d ns | %s %b | %2d %2d | %b (%3d) | C=%b Z=%b V=%b N=%b",
                     $time - 10, name, op, x, y, result, result, carry, zero, overflow, negative);
        end
    endtask

    task show_md(input [3:0] op, input [3:0] x, input [3:0] y, input [8*4-1:0] name);
        begin
            run_md(op, x, y);
            if (op == 4'b1000)
                $display("  %5d ns | %s %b | %2d %2d | %b (%3d) | product = %0d, %0d cycles",
                         $time - 5, name, op, x, y, result, result, result, cycles);
            else
                $display("  %5d ns | %s %b | %2d %2d | %b       | q = %0d, r = %0d, dbz=%b, %0d cycles",
                         $time - 5, name, op, x, y, result, result[3:0], result[7:4], div_by_zero, cycles);
        end
    endtask

    integer i, errors, op_i;
    reg [7:0] ab;

    initial begin
        errors = 0;
        $display("============================================================");
        $display(" Student: Vu Quoc Anh    Roll number: SE203519");
        $display(" Project: ALU4    Testbench: tb_alu_4bit (system test)");
        $display("============================================================");
        #12 rst = 0;

        // ================= Part 1: examples =================
        $display("Part 1: example table (time = when the row is valid)");
        $display("  time     | Op   code | A  B  | result         | flags / notes");
        $display("  ---------+-----------+-------+----------------+------------------------------");
        show_comb(4'b0000,  5,  3, "ADD ");
        show_comb(4'b0000, 15,  1, "ADD ");
        show_comb(4'b0001,  5,  3, "SUB ");
        show_comb(4'b0001,  3,  5, "SUB ");
        show_comb(4'b0010, 12, 10, "AND ");
        show_comb(4'b0011, 12, 10, "OR  ");
        show_comb(4'b0100, 12, 10, "XOR ");
        show_comb(4'b0101, 12,  0, "NOT ");
        show_comb(4'b0110, 11,  0, "SHL ");
        show_comb(4'b0111, 11,  0, "SHR ");
        show_md  (4'b1000, 13, 11, "MUL ");
        show_md  (4'b1000, 15, 15, "MUL ");
        show_md  (4'b1001, 13,  4, "DIV ");
        show_md  (4'b1001, 15,  3, "DIV ");
        show_md  (4'b1001,  9,  0, "DIV ");

        $display("Part 2: self checks");
        // ================= Part 2a: single cycle, exhaustive =================
        for (op_i = 0; op_i < 16; op_i = op_i + 1) begin
            if (op_i != 8 && op_i != 9) begin
                for (i = 0; i < 256; i = i + 1) begin
                    opcode = op_i; {a, b} = i; #1;
                    model;
                    if (result !== {4'b0, exp_r} || carry !== exp_c || overflow !== exp_v ||
                        zero !== (exp_r == 0) || negative !== exp_r[3] ||
                        busy !== 0 || div_by_zero !== 0) begin
                        errors = errors + 1;
                        if (errors <= 10)
                            $display("  FAIL op=%b a=%0d b=%0d got %b C%b V%b expected %b C%b V%b",
                                     opcode, a, b, result, carry, overflow, exp_r, exp_c, exp_v);
                    end
                end
            end
        end
        $display("  2a done: 3584 single cycle checks, errors so far = %0d", errors);

        // ================= Part 2b: MUL / DIV, exhaustive =================
        for (i = 0; i < 256; i = i + 1) begin
            ab = i;
            run_md(4'b1000, ab[7:4], ab[3:0]);
            if (result !== ab[7:4] * ab[3:0] || cycles != 5 || zero !== (result == 0) ||
                carry !== 0 || overflow !== 0 || negative !== 0 || div_by_zero !== 0) begin
                errors = errors + 1;
                if (errors <= 10) $display("  FAIL MUL %0d*%0d got %0d", ab[7:4], ab[3:0], result);
            end
            run_md(4'b1001, ab[7:4], ab[3:0]);
            if (ab[3:0] == 0) begin
                if (div_by_zero !== 1 || result[3:0] !== 4'b1111 || result[7:4] !== ab[7:4]) begin
                    errors = errors + 1;
                    if (errors <= 10) $display("  FAIL DIV %0d/0", ab[7:4]);
                end
            end
            else if (result[3:0] !== ab[7:4] / ab[3:0] || result[7:4] !== ab[7:4] % ab[3:0] ||
                     div_by_zero !== 0 || cycles != 5 || zero !== (result == 0) ||
                     carry !== 0 || overflow !== 0 || negative !== 0) begin
                errors = errors + 1;
                if (errors <= 10) $display("  FAIL DIV %0d/%0d got q=%0d r=%0d",
                                           ab[7:4], ab[3:0], result[3:0], result[7:4]);
            end
        end
        $display("  2b done: 512 MUL/DIV checks, errors so far = %0d", errors);

        // ================= Part 2c: protocol =================
        // 4a: pulse start with a single-cycle opcode -> muldiv must stay idle
        @(negedge clk); opcode = 4'b0000; a = 2; b = 3; start = 1;
        @(negedge clk); start = 0;
        if (busy !== 0 || result !== 8'd5) begin
            errors = errors + 1; $display("  FAIL 2c/4a: start with ADD started muldiv");
        end

        // 4b: after a MUL finishes, ADD must use a and b again (adder handed back)
        run_md(4'b1000, 3, 3);
        opcode = 4'b0000; a = 6; b = 7; #1;
        if (result !== 8'd13 || busy !== 0) begin
            errors = errors + 1; $display("  FAIL 2c/4b: adder not returned after MUL");
        end

        // 4c: div_by_zero visible only while opcode = DIV
        run_md(4'b1001, 5, 0);
        if (div_by_zero !== 1) begin errors = errors + 1; $display("  FAIL 2c/4c: dbz not set"); end
        opcode = 4'b0010; #1;
        if (div_by_zero !== 0) begin errors = errors + 1; $display("  FAIL 2c/4c: dbz not gated"); end
        opcode = 4'b1001; #1;
        if (div_by_zero !== 1) begin errors = errors + 1; $display("  FAIL 2c/4c: dbz lost"); end

        // 4d: reset clears muldiv registers and status
        rst = 1; #1;
        if (result !== 8'd0 || zero !== 1 || done !== 0 || busy !== 0 || div_by_zero !== 0) begin
            errors = errors + 1; $display("  FAIL 2c/4d: reset");
        end
        #10 rst = 0;
        $display("  2c done: protocol checks, errors so far = %0d", errors);

        if (errors == 0)
            $display("PASS: tb_alu_4bit (Vu Quoc Anh, SE203519), 3584 single cycle + 512 MUL/DIV + protocol checks, 0 errors");
        else
            $display("FAILED: tb_alu_4bit, %0d errors", errors);
        $finish;
    end
endmodule
