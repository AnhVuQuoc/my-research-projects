; prog_wrap.asm: PC wraps from 255 to 0
        BNZ  high           ; Z = 0 after reset: taken
        HLT
.org 254
high:   LDI  R1, 7
        SUB  R3, R3, R3     ; Z = 1
                            ; PC + 1 of 255 wraps to 0: BNZ is NOT taken now, then HLT
