; prog_arith.asm: carry, borrow and wrap-around
        LDI  R1, 200
        LDI  R2, 100
        ADD  R3, R1, R2     ; 300 mod 256 = 44, C = 1
        SUB  R4, R2, R1     ; 100 - 200 = 156, borrow C = 1
        SUB  R5, R1, R2     ; 100, C = 0
        SUB  R6, R5, R5     ; 0, Z = 1, C = 0
        ADDI R7, 255        ; 0 + 255 = 255, C = 0
        ADDI R7, 1          ; 256 -> 0, Z = 1, C = 1
        HLT
