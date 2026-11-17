// =============================================================================
// File        : apb_regs8.v
// Module      : apb_regs8
// Project     : RISC-8 SoC: 8-bit pipelined CPU + 8-bit Timer / SAR ADC peripheral
// Author      : Vu Quoc Anh (SE203519)
// Job         : The 16 registers on an 8-bit APB slave (always ready, no error),
//               the combinational read mux, the FIFO pop on a read of ADC_DATA,
//               the sticky event flags (W1C, a same-clock event wins over the
//               clear), the level-based FIFO watermark flag, and irq.
// Map         : 0 TMR_CTRL  1 TMR_PRESC  2 TMR_LOAD   3 TMR_CMP   4 TMR_CNT (RO)
//               5 ADC_CTRL  6 ADC_SMP    7 ADC_DIV    8 THR_LO    9 THR_HI
//               A ADC_DATA (RO, pop)  B ADC_RCH (RO)  C ADC_STAT (RO)
//               D IRQ_EN    E IRQ_STAT (W1C)          F ID = 0xA8 (RO)
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module apb_regs8 (
    input  wire       clk,
    input  wire       rst_n,
    // ---- APB slave ----
    input  wire       psel,
    input  wire       penable,
    input  wire       pwrite,
    input  wire [3:0] paddr,
    input  wire [7:0] pwdata,
    output wire [7:0] prdata,
    output wire       pready,
    output wire       pslverr,
    // ---- timer ----
    output reg        tmr_en,
    output reg        tmr_oneshot,
    output reg  [7:0] tmr_presc,
    output reg  [7:0] tmr_load,
    output reg  [7:0] tmr_cmp,
    input  wire [7:0] tmr_cnt,
    input  wire       tmr_ovf,
    input  wire       tmr_cmp_ev,
    input  wire       tmr_oneshot_done,
    // ---- ADC ----
    output reg        adc_en,
    output reg        adc_start,            // 1-clock pulse, 1 clock after the write
    output reg  [1:0] adc_trig_sel,
    output reg  [1:0] adc_ch,
    output reg  [7:0] adc_smp,
    output reg  [7:0] adc_div,
    output reg  [7:0] thr_lo,
    output reg  [7:0] thr_hi,
    input  wire       adc_busy,
    input  wire       adc_eoc,
    input  wire       adc_wd,               // result outside [thr_lo, thr_hi]
    input  wire       adc_trig_miss,
    // ---- FIFO ----
    input  wire [9:0] fifo_dout,            // {ch, data} of the oldest entry
    input  wire [3:0] fifo_level,
    input  wire       fifo_empty,
    input  wire       fifo_full,
    input  wire       fifo_ovr,
    output wire       fifo_pop,
    // ---- interrupt ----
    output wire       irq
);

    localparam A_TMR_CTRL = 4'h0, A_TMR_PRESC = 4'h1, A_TMR_LOAD = 4'h2, A_TMR_CMP = 4'h3, A_TMR_CNT = 4'h4,
               A_ADC_CTRL = 4'h5, A_ADC_SMP = 4'h6, A_ADC_DIV = 4'h7, A_THR_LO = 4'h8, A_THR_HI = 4'h9,
               A_ADC_DATA = 4'hA, A_ADC_RCH = 4'hB, A_ADC_STAT = 4'hC, A_IRQ_EN = 4'hD, A_IRQ_STAT = 4'hE;
    localparam [7:0] ID_VALUE = 8'hA8;

    wire access = psel & penable;                     // APB access phase
    wire wr     = access & pwrite;
    wire rd     = access & ~pwrite;

    reg  [1:0] adc_wm;                                // watermark select: 1, 2, 4 or 8 entries
    reg  [5:0] flags;                                 // sticky: TRIG_MISS FIFO_OVR ADC_WD ADC_EOC TMR_CMP TMR_OVF
    reg  [6:0] irq_en;
    reg  [1:0] lch;                                   // channel of the last popped result
    reg        lvalid;
    wire [3:0] wm_level = 4'd1 << adc_wm;             // 1, 2, 4, 8
    wire       wm_flag  = ({1'b0, fifo_level} >= {1'b0, wm_level});
    wire [5:0] set      = {adc_trig_miss, fifo_ovr, adc_wd, adc_eoc, tmr_cmp_ev, tmr_ovf};
    wire [5:0] clr      = (wr && paddr == A_IRQ_STAT) ? pwdata[5:0] : 6'd0;

    assign pready   = 1'b1;
    assign pslverr  = 1'b0;
    assign fifo_pop = rd & (paddr == A_ADC_DATA);
    assign irq      = |({wm_flag, flags} & irq_en);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tmr_en <= 1'b0; tmr_oneshot <= 1'b0; tmr_presc <= 8'h00; tmr_load <= 8'hFF; tmr_cmp <= 8'h80;
            adc_en <= 1'b0; adc_start <= 1'b0; adc_trig_sel <= 2'd0; adc_ch <= 2'd0; adc_wm <= 2'd0;
            adc_smp <= 8'h04; adc_div <= 8'h00; thr_lo <= 8'h00; thr_hi <= 8'hFF;
            irq_en <= 7'd0; flags <= 6'd0; lch <= 2'd0; lvalid <= 1'b0;
        end
        else begin
            adc_start <= wr && (paddr == A_ADC_CTRL) && pwdata[1];
            flags     <= (flags & ~clr) | set;            // a same-clock event wins
            if (fifo_pop && !fifo_empty) begin lch <= fifo_dout[9:8]; lvalid <= 1'b1; end
            if (wr) begin
                case (paddr)
                    A_TMR_CTRL : begin tmr_en <= pwdata[0]; tmr_oneshot <= pwdata[1]; end
                    A_TMR_PRESC: tmr_presc <= pwdata;
                    A_TMR_LOAD : tmr_load  <= pwdata;
                    A_TMR_CMP  : tmr_cmp   <= pwdata;
                    A_ADC_CTRL : begin adc_en <= pwdata[0]; adc_trig_sel <= pwdata[3:2];
                                       adc_ch <= pwdata[5:4]; adc_wm <= pwdata[7:6]; end
                    A_ADC_SMP  : adc_smp   <= pwdata;
                    A_ADC_DIV  : adc_div   <= pwdata;
                    A_THR_LO   : thr_lo    <= pwdata;
                    A_THR_HI   : thr_hi    <= pwdata;
                    A_IRQ_EN   : irq_en    <= pwdata[6:0];
                    default    : ;                    // RO, W1C (above) and ID: no storage
                endcase
            end
            if (tmr_oneshot_done && !(wr && paddr == A_TMR_CTRL)) tmr_en <= 1'b0;
        end
    end

    reg [7:0] rmux;
    always @(*) begin
        case (paddr)
            A_TMR_CTRL : rmux = {6'd0, tmr_oneshot, tmr_en};
            A_TMR_PRESC: rmux = tmr_presc;
            A_TMR_LOAD : rmux = tmr_load;
            A_TMR_CMP  : rmux = tmr_cmp;
            A_TMR_CNT  : rmux = tmr_cnt;
            A_ADC_CTRL : rmux = {adc_wm, adc_ch, adc_trig_sel, 1'b0, adc_en};   // START reads 0
            A_ADC_SMP  : rmux = adc_smp;
            A_ADC_DIV  : rmux = adc_div;
            A_THR_LO   : rmux = thr_lo;
            A_THR_HI   : rmux = thr_hi;
            A_ADC_DATA : rmux = fifo_empty ? 8'h00 : fifo_dout[7:0];
            A_ADC_RCH  : rmux = {~fifo_empty, lvalid, lch, 2'b00, fifo_empty ? 2'b00 : fifo_dout[9:8]};
            A_ADC_STAT : rmux = {wm_flag, adc_busy, fifo_full, fifo_empty, fifo_level};
            A_IRQ_EN   : rmux = {1'b0, irq_en};
            A_IRQ_STAT : rmux = {1'b0, wm_flag, flags};
            default    : rmux = ID_VALUE;
        endcase
    end
    assign prdata = psel ? rmux : 8'h00;              // 0 when not selected: can be OR-ed

endmodule

`default_nettype wire
