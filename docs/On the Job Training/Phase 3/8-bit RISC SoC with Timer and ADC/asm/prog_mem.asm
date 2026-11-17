; prog_mem.asm: register-indirect LD/ST, address and data forwarding, load-use on port A and port B
        LDI  R1, 0x80       ; address
        LDI  R2, 0x5A       ; data
        ST   R2, [R1]       ; M[0x80] = 0x5A  (R1 from WB, R2 from MEM)
        LD   R3, [R1]       ; R3 = 0x5A       (R1 by RF bypass)
        ADD  R4, R3, R3     ; load-use stall on port A and B -> R4 = 0xB4
        ADDI R1, 1          ; R1 = 0x81
        ST   R4, [R1]       ; M[0x81] = 0xB4  (address R1 from MEM, data R4 from WB)
        LD   R5, [R1]       ; R5 = 0xB4
        ST   R5, [R0]       ; load-use stall on port B (store data) -> M[0] = 0xB4
        LD   R6, [R0]       ; R6 = 0xB4 (memory written 1 cycle earlier)
        HLT
