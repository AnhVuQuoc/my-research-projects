; prog_logic.asm: logic and shifts; R0 is an ordinary register
        LDI  R1, 0xF0
        LDI  R2, 0x3C
        AND  R3, R1, R2     ; 0x30
        OR   R4, R1, R2     ; 0xFC
        XOR  R5, R1, R2     ; 0xCC
        SHL  R6, R1         ; 0xE0, C = old bit 7 = 1
        SHR  R7, R2         ; 0x1E, C = old bit 0 = 0
        XOR  R0, R1, R1     ; 0, Z = 1 (C unchanged = 0)
        HLT
