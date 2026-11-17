; prog_branch.asm: loop with BNZ, BZ taken, JMP, BNZ not taken, HLT drains
        LDI  R1, 5          ; counter
        LDI  R2, 0          ; sum
loop:   ADD  R2, R2, R1     ; sum += counter
        ADDI R1, 255        ; counter - 1 (Z = 1 when it reaches 0)
        BNZ  loop           ; flag stall (ADDI just before), taken 4 times
        BZ   skip           ; Z = 1: taken (no stall: BNZ writes no flag)
        LDI  R3, 99         ; never runs
skip:   JMP  next
        LDI  R3, 77         ; never runs
next:   LDI  R4, 1
        SUB  R5, R4, R4     ; 0, Z = 1, no borrow
        BNZ  6              ; flag stall, NOT taken
        HLT
        LDI  R6, 1          ; fetched while HLT is in ID: never runs
