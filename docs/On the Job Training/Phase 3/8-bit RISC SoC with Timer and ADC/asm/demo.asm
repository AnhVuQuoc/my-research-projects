; demo.asm: every forwarding path, no stall (program.mem)
        LDI  R1, 5          ; R1 = 5
        LDI  R2, 3          ; R2 = 3
        ADD  R3, R1, R2     ; R3 = 8    R1 from WB (dist 2), R2 from MEM (dist 1)
        SUB  R4, R1, R2     ; R4 = 2    R1 by RF bypass (dist 3), R2 from WB
        XOR  R5, R3, R4     ; R5 = 10   R3 from WB, R4 from MEM
        SHL  R6, R5         ; R6 = 20   R5 from MEM
        ADDI R6, 100        ; R6 = 120  port A reads rd = R6, from MEM
        HLT
