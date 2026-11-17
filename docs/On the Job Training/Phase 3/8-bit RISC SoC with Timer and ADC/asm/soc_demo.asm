; soc_demo.asm: firmware for the RISC-8 SoC (CPU + Timer / SAR ADC)
; Register use: main R0..R4 (R0 stays 0), ISR R5 (buffer pointer), R6, R7.
        JMP  main
.org 0x10
; ---- ISR: drain the FIFO into the buffer at R5, clear the sticky flags --------
isr:    LDI  R6, 0xFC          ; ADC_STAT
        LD   R7, [R6]
        LDI  R6, 0x10          ; EMPTY bit
        AND  R7, R7, R6
        BNZ  isr_done          ; FIFO empty: done
        LDI  R6, 0xFA          ; ADC_DATA (pop)
        LD   R7, [R6]
        ST   R7, [R5]          ; buffer[R5] = sample
        ADDI R5, 1
        JMP  isr
isr_done: LDI R6, 0xFE         ; IRQ_STAT
        LDI  R7, 0x3F
        ST   R7, [R6]          ; clear all sticky flags (W1C)
        RETI
.org 0x20
main:
; ---- A: the peripheral answers ------------------------------------------------
        LDI  R4, 0xFF          ; ID
        LD   R1, [R4]
        LDI  R4, 0x80
        ST   R1, [R4]          ; M[80] = A8
; ---- B: software conversion of ch1, polling -----------------------------------
        LDI  R4, 0xF6          ; ADC_SMP = 3
        LDI  R1, 3
        ST   R1, [R4]
        LDI  R4, 0xF5          ; ADC_CTRL = EN | START | CH1
        LDI  R1, 0x13
        ST   R1, [R4]
        LDI  R4, 0xFC          ; ADC_STAT
        LDI  R2, 0x10          ; EMPTY mask
wait_b: LD   R1, [R4]
        AND  R1, R1, R2
        BNZ  wait_b            ; still empty
        LDI  R4, 0xFB          ; ADC_RCH, peek before the pop
        LD   R1, [R4]
        LDI  R3, 0x81
        ST   R1, [R3]          ; M[81] = 81 (VALID, CH1)
        LDI  R4, 0xFA          ; ADC_DATA, pop
        LD   R1, [R4]
        LDI  R3, 0x82
        ST   R1, [R3]          ; M[82] = 56 (1.111 V)
        LDI  R4, 0xFB          ; ADC_RCH after the pop: latched channel
        LD   R1, [R4]
        LDI  R3, 0x83
        ST   R1, [R3]          ; M[83] = 50 (LVALID, LCH = 1, FIFO empty)
; ---- C: timer-triggered ch2, watermark 4, interrupt and WFI -------------------
        LDI  R5, 0x90          ; ISR buffer pointer
        LDI  R4, 0xF1          ; TMR_PRESC = 3
        LDI  R1, 3
        ST   R1, [R4]
        LDI  R4, 0xF2          ; TMR_LOAD = 24: 100-clock period
        LDI  R1, 24
        ST   R1, [R4]
        LDI  R4, 0xFD          ; IRQ_EN = FIFO_WM
        LDI  R1, 0x40
        ST   R1, [R4]
        LDI  R4, 0xF5          ; ADC_CTRL = WM4 | CH2 | TRIG = overflow | EN
        LDI  R1, 0xA5
        ST   R1, [R4]
        LDI  R4, 0xF0          ; TMR_CTRL = EN
        LDI  R1, 1
        ST   R1, [R4]
        EI
        LDI  R3, 0x98          ; stop after 8 samples
sleep_c: WFI
        SUB  R2, R5, R3
        BNZ  sleep_c
        DI
        LDI  R4, 0xF0          ; timer off
        LDI  R1, 0
        ST   R1, [R4]
        LDI  R4, 0xF5          ; ADC off
        ST   R1, [R4]
        LDI  R4, 0xFD          ; IRQ_EN = 0: this part no longer uses the irq pin
        ST   R1, [R4]
; ---- D: window comparator, ch3 = 3.0 V (232) above THR_HI = 100 ---------------
        LDI  R4, 0xF9
        LDI  R1, 100
        ST   R1, [R4]
        LDI  R4, 0xFE          ; clear old flags
        LDI  R1, 0x3F
        ST   R1, [R4]
        LDI  R4, 0xF5          ; ADC_CTRL = EN | START | CH3
        LDI  R1, 0x33
        ST   R1, [R4]
        LDI  R4, 0xFE          ; poll IRQ_STAT.ADC_WD
        LDI  R2, 0x08
wait_d: LD   R1, [R4]
        AND  R1, R1, R2
        BZ   wait_d
        LD   R1, [R4]
        LDI  R3, 0x84
        ST   R1, [R3]          ; M[84] = 4C (FIFO_WM | ADC_WD | ADC_EOC)
        LDI  R4, 0xFA
        LD   R1, [R4]
        LDI  R3, 0x85
        ST   R1, [R3]          ; M[85] = E8
        LDI  R4, 0xF9          ; THR_HI back to 255
        LDI  R1, 0xFF
        ST   R1, [R4]
; ---- F: 2 queued results, an ALU op on an I/O pointer, 2 back-to-back pops ----
        LDI  R4, 0xF5          ; EN | START, ch0
        LDI  R1, 0x03
        ST   R1, [R4]
        LDI  R4, 0xFC
        LDI  R2, 0x0F          ; LEVEL mask
wait_f1: LD  R1, [R4]
        AND  R1, R1, R2
        BZ   wait_f1
        LDI  R4, 0xF5          ; EN | START, ch1
        LDI  R1, 0x13
        ST   R1, [R4]
        LDI  R4, 0xFC
        LDI  R2, 0x02          ; LEVEL = 2
wait_f2: LD  R1, [R4]
        AND  R1, R1, R2
        BZ   wait_f2
        LDI  R4, 0xFA
        ADD  R3, R4, R0        ; pointer arithmetic: must NOT pop
        LD   R1, [R3]          ; pop 1
        LD   R2, [R3]          ; pop 2, back-to-back
        LDI  R3, 0x86
        ST   R1, [R3]          ; M[86] = 1F (ch0, 0.40 V)
        LDI  R3, 0x87
        ST   R2, [R3]          ; M[87] = 56 (ch1)
        LDI  R4, 0xFC
        LD   R1, [R4]
        LDI  R3, 0x88
        ST   R1, [R3]          ; M[88] = 10 (empty)
; ---- G: continuous mode without reading: FIFO overflow --------------------------
        LDI  R4, 0xFE          ; clear the sticky flags left by D and F
        LDI  R1, 0x3F
        ST   R1, [R4]
        LDI  R4, 0xF5          ; ADC_CTRL = EN | continuous, ch0
        LDI  R1, 0x0D
        ST   R1, [R4]
        LDI  R4, 0xFE
        LDI  R2, 0x10          ; FIFO_OVR
wait_g: LD   R1, [R4]
        AND  R1, R1, R2
        BZ   wait_g
        LDI  R4, 0xF5          ; ADC off
        LDI  R1, 0
        ST   R1, [R4]
        LDI  R4, 0xFE
        LD   R1, [R4]
        LDI  R3, 0x89
        ST   R1, [R3]          ; M[89] = 54 (FIFO_WM | FIFO_OVR | ADC_EOC)
        LDI  R4, 0xFC
        LD   R1, [R4]
        LDI  R3, 0x8A
        ST   R1, [R3]          ; M[8A] = A8 (WM | FULL | LEVEL 8)
; ---- E: PWM 30 % duty, then halt (the timer keeps running) ---------------------
        LDI  R4, 0xF1
        LDI  R1, 0
        ST   R1, [R4]          ; PRESC = 0
        LDI  R4, 0xF2
        LDI  R1, 9
        ST   R1, [R4]          ; LOAD = 9
        LDI  R4, 0xF3
        LDI  R1, 3
        ST   R1, [R4]          ; CMP = 3
        LDI  R4, 0xF0
        LDI  R1, 1
        ST   R1, [R4]          ; timer on
        HLT
