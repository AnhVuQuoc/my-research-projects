// =============================================================================
// File        : isa_reference_model.v
// Module      : isa_reference_model   (SIMULATION ONLY, not synthesizable)
// Project     : 4-bit RISC CPU, 5-stage pipeline (Level 1 upgrade)
// Author      : Vu Quoc Anh (SE203519)
// Course      : Phase 1 Capstone, Lecturer: Shivashish Pal
// Job         : Independent "golden" model of the ISA. It executes ONE whole
//               instruction per call of task step, exactly as the ISA table
//               says, with no pipeline. It is written in a different style
//               from the RTL on purpose (integer arithmetic, a >= b compare
//               for the SUB carry, literal opcodes, no shared header), so a
//               mistake in the RTL is not copied into the reference.
// Use         : tb_cpu fills imem/dmem, calls reset_state, then calls step
//               each time the CPU retires an instruction and compares state.
// State       : imem[16], dmem[16], r[4], pc, zf, cf
// After step  : last_pc, last_reg_we, last_rd, last_value,
//               last_mem_we, last_addr, last_mem_value describe what the
//               instruction just executed did.
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module isa_reference_model;

    reg [11:0] imem [0:15];
    reg [3:0]  dmem [0:15];
    reg [3:0]  r    [0:3];
    reg [3:0]  pc;
    reg        zf, cf;

    reg [3:0]  last_pc;
    reg        last_reg_we;
    reg [1:0]  last_rd;
    reg [3:0]  last_value;
    reg        last_mem_we;
    reg [3:0]  last_addr;
    reg [3:0]  last_mem_value;

    integer    steps;

    task reset_state;
        begin
            pc = 4'd0; zf = 1'b0; cf = 1'b0;
            r[0] = 4'd0; r[1] = 4'd0; r[2] = 4'd0; r[3] = 4'd0;
            steps = 0;
        end
    endtask

    task step;
        reg [11:0] w;
        reg [3:0]  op, imm, vd, vs;
        reg [1:0]  d, s;
        integer    t;
        begin
            w   = imem[pc];
            op  = w[11:8]; d = w[7:6]; s = w[5:4]; imm = w[3:0];
            vd  = r[d];    vs = r[s];
            last_pc     = pc;
            last_reg_we = 1'b0; last_rd = d; last_value = 4'd0;
            last_mem_we = 1'b0; last_addr = imm; last_mem_value = 4'd0;
            pc  = pc + 4'd1;                       // default next address
            case (op)
                4'h0: begin t = vd + vs;           // ADD
                            last_value = t % 16; cf = (t > 15);
                            zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h1: begin t = vd - vs;           // SUB
                            if (t < 0) t = t + 16;
                            last_value = t; cf = (vd >= vs);
                            zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h2: begin last_value = vd & vs; zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h3: begin last_value = vd | vs; zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h4: begin last_value = vd ^ vs; zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h5: begin last_value = ~vd;     zf = (last_value == 0); last_reg_we = 1'b1; end
                4'h6: begin last_value = imm;       last_reg_we = 1'b1; end   // LDI
                4'h7: begin last_value = vs;        last_reg_we = 1'b1; end   // MOV
                4'h8: begin last_value = dmem[imm]; last_reg_we = 1'b1; end   // LOAD
                4'h9: begin dmem[imm] = vd; last_mem_we = 1'b1;               // STORE
                            last_mem_value = vd; end
                4'hA: pc = imm;                                               // JMP
                4'hB: if (zf) pc = imm;                                       // JZ
                default: ;                                                    // NOP
            endcase
            if (last_reg_we) r[d] = last_value;
            steps = steps + 1;
        end
    endtask

endmodule

`default_nettype wire
