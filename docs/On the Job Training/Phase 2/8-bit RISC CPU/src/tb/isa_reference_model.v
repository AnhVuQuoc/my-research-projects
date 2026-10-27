// =============================================================================
// File        : isa_reference_model.v
// Module      : isa_reference_model   (SIMULATION ONLY)
// Project     : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : Independent golden model of the ISA: 1 whole instruction per call
//               of task step, no pipeline. Written differently from the RTL on
//               purpose: integer arithmetic, a < b for the SUB borrow, literal
//               opcodes, no shared header.
// State       : imem[256], dmem[256], r[8], pc, zf, cf, halted
// After step  : last_pc, last_reg_we, last_rd, last_value, last_mem_we,
//               last_addr, last_mem_value, last_op
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module isa_reference_model;

    reg [15:0] imem [0:255];
    reg [7:0]  dmem [0:255];
    reg [7:0]  r    [0:7];
    reg [7:0]  pc;
    reg        zf, cf, halted;

    reg [7:0]  last_pc;
    reg        last_reg_we;
    reg [2:0]  last_rd;
    reg [7:0]  last_value;
    reg        last_mem_we;
    reg [7:0]  last_addr;
    reg [7:0]  last_mem_value;
    reg [3:0]  last_op;
    integer    steps;
    integer    k;

    task reset_state;
        begin
            pc = 8'd0; zf = 1'b0; cf = 1'b0; halted = 1'b0; steps = 0;
            for (k = 0; k < 8; k = k + 1) r[k] = 8'd0;
        end
    endtask

    task step;
        reg [15:0] w;
        reg [3:0]  op;
        reg [2:0]  d, s1, s2;
        reg [7:0]  imm, va, vb, vd;
        integer    t;
        begin
            w = imem[pc];
            op = w[15:12]; d = w[11:9]; s1 = w[8:6]; s2 = w[5:3]; imm = w[7:0];
            va = r[s1]; vb = r[s2]; vd = r[d];
            last_pc = pc; last_op = op; last_reg_we = 1'b0; last_rd = d; last_value = 8'd0;
            last_mem_we = 1'b0; last_addr = 8'd0; last_mem_value = 8'd0;
            pc = pc + 8'd1;
            case (op)
                4'h1: begin t = va + vb; last_value = t % 256; cf = (t > 255);
                            zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h2: begin t = va - vb; if (t < 0) t = t + 256; last_value = t;
                            cf = (va < vb); zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h3: begin last_value = va & vb; zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h4: begin last_value = va | vb; zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h5: begin last_value = va ^ vb; zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h6: begin t = va * 2; last_value = t % 256; cf = (va >= 128);
                            zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h7: begin last_value = va / 2; cf = va % 2;
                            zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h8: begin last_value = imm; last_reg_we = 1'b1; end
                4'h9: begin t = vd + imm; last_value = t % 256; cf = (t > 255);
                            zf = (last_value == 0); last_reg_we = 1'b1; end
                4'hA: begin last_value = dmem[va]; last_reg_we = 1'b1; end
                4'hB: begin dmem[va] = vd; last_mem_we = 1'b1; last_addr = va; last_mem_value = vd; end
                4'hC: pc = imm;
                4'hD: if (zf)  pc = imm;
                4'hE: if (!zf) pc = imm;
                4'hF: begin halted = 1'b1; pc = last_pc; end
                default: ;                                  // NOP
            endcase
            if (last_reg_we) r[d] = last_value;
            steps = steps + 1;
        end
    endtask

endmodule

`default_nettype wire
