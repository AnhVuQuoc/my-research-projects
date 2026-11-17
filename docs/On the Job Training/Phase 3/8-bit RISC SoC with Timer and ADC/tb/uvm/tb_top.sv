// =============================================================================
// File        : tb/uvm/tb_top.sv   clock, reset, DUT, interfaces, analog model, run_test
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
`timescale 1ns / 1ps
module tb_top;
    import uvm_pkg::*;
    import timer_adc_pkg::*;
    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;
    initial begin repeat (5) @(posedge clk); rst_n = 1; end
    apb_if aif (clk, rst_n);
    adc_if dif (clk, rst_n);
    timer_adc8_top dut (.clk(clk), .rst_n(rst_n), .psel(aif.psel), .penable(aif.penable), .pwrite(aif.pwrite), .paddr(aif.paddr),
        .pwdata(aif.pwdata), .prdata(aif.prdata), .pready(aif.pready), .pslverr(aif.pslverr), .irq(dif.irq), .pwm_out(dif.pwm),
        .adc_sample(dif.sample), .adc_ch(dif.ch), .adc_dac(dif.dac), .adc_cmp(dif.cmp));
    sar_afe_model #(.VREF(3.3)) afe (dif);
    assign dif.eoc = dut.adc_eoc;           assign dif.busy = dut.adc_busy;     assign dif.tmr_ovf = dut.tmr_ovf;
    assign dif.tmr_cmp = dut.tmr_cmp_ev;    assign dif.trig_miss = dut.adc_trig_miss;  assign dif.wd = dut.adc_wd;
    assign dif.fifo_ovr = dut.fifo_ovr;     assign dif.result = dut.adc_result; assign dif.result_ch = dut.adc_res_ch;
    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", aif);
        uvm_config_db#(virtual adc_if)::set(null, "*", "adc_vif", dif);
        if ($test$plusargs("DUMP")) begin $dumpfile("tb_top.vcd"); $dumpvars(0, tb_top); end
        run_test();
    end
endmodule
