`timescale 1ns/1ps
`include "tb_defs.vh"

module uart_seq_auto #(
  parameter AW = `U_AW,
  parameter DW = `U_DW
)(
  input  wire          pclk,
  input  wire          presetn,
  output wire          psel_o,
  output wire          penable_o,
  output wire          pwrite_o,
  output wire [AW-1:0] paddr_o,
  output wire [DW-1:0] pwdata_o,
  input  wire [DW-1:0] prdata_i,
  input  wire          pready_i,
  input  wire          pslverr_i,
  output wire          rx_o
);

  integer seed;
  integer cur_div;
  reg     cur_par_en, cur_par_odd, cur_stop2;

  initial begin
    seed        = 32'h5EED_0900;
    cur_div     = `BAUD_DIV;
    cur_par_en  = 1'b0;
    cur_par_odd = 1'b0;
    cur_stop2   = 1'b0;
  end

  apb_master_bfm #(.AW(AW), .DW(DW)) m (
    .pclk      (pclk),
    .presetn   (presetn),
    .psel_o    (psel_o),
    .penable_o (penable_o),
    .pwrite_o  (pwrite_o),
    .paddr_o   (paddr_o),
    .pwdata_o  (pwdata_o),
    .prdata_i  (prdata_i),
    .pready_i  (pready_i),
    .pslverr_i (pslverr_i)
  );

  serial_driver ser ( .line_o (rx_o) );

  task wr;   input [AW-1:0] a; input [DW-1:0] d; begin m.write(a, d); end endtask
  task rd;   input [AW-1:0] a;                   begin m.read(a);     end endtask
  task idle; input integer c;                    begin m.idle(c);     end endtask

  task set_seed; input integer s; begin seed = s; end endtask

  task configure;
    input integer div;
    input         par_en;
    input         par_odd;
    input         stop2;
    input         loopback;
    input         irq_en;
    reg [31:0] c;
    begin
      cur_div     = div;
      cur_par_en  = par_en;
      cur_par_odd = par_odd;
      cur_stop2   = stop2;

      c = 32'd0;
      c[`CTRL_EN]       = 1'b1;
      c[`CTRL_PAR_EN]   = par_en;
      c[`CTRL_PAR_ODD]  = par_odd;
      c[`CTRL_STOP2]    = stop2;
      c[`CTRL_LOOPBACK] = loopback;
      c[`CTRL_IRQ_EN]   = irq_en;

      m.write(`UREG_BAUD, div);
      m.write(`UREG_CTRL, c);
      ser.set_bit_period_cycles(div);
      m.idle(2);
    end
  endtask

  task random_config;
    input integer loopback;
    input integer irq_en;
    integer r, par, stop2, div;
    begin
      r = $random(seed); if (r < 0) r = -r;
      par   = r % 3;
      stop2 = (r / 3) % 2;
      div   = ((r / 6) % 2) ? `BAUD_DIV_ALT : `BAUD_DIV;
      case (par)
        `PAR_NONE: configure(div, 1'b0, 1'b0, (stop2!=0), (loopback!=0), (irq_en!=0));
        `PAR_EVEN: configure(div, 1'b1, 1'b0, (stop2!=0), (loopback!=0), (irq_en!=0));
        default:   configure(div, 1'b1, 1'b1, (stop2!=0), (loopback!=0), (irq_en!=0));
      endcase
    end
  endtask

  task set_line_style; input integer s; begin ser.set_style(s); end endtask

  task send_byte_fc;
    input  [7:0]  d;
    output        accepted;
    begin
      m.read(`UREG_STATUS);
      if (!m.last_rdata[`ST_TX_FULL]) begin
        m.write(`UREG_TXDATA, {24'd0, d});
        accepted = 1'b1;
      end else begin
        accepted = 1'b0;
      end
    end
  endtask

  task send_burst;
    input integer n;
    integer k, guard, r;
    reg ok;
    reg [7:0] d;
    begin
      k = 0; guard = 0;
      while (k < n && guard < n*40) begin
        r = $random(seed); if (r < 0) r = -r;
        d = r & 32'hFF;
        send_byte_fc(d, ok);
        if (ok) k = k + 1;
        else    m.idle(cur_div);
        guard = guard + 1;
      end
    end
  endtask

  task recv_byte;
    input [7:0] d;
    begin ser.send_frame(d, cur_par_en, cur_par_odd, cur_stop2); end
  endtask

  task recv_bad_stop;
    input [7:0] d;
    begin ser.send_frame_bad_stop(d, cur_par_en, cur_par_odd); end
  endtask

  task recv_bad_parity;
    input [7:0] d;
    begin ser.send_frame_bad_parity(d, cur_par_odd); end
  endtask

  task read_rx_fc;
    output accepted;
    begin
      m.read(`UREG_STATUS);
      if (!m.last_rdata[`ST_RX_EMPTY]) begin
        m.read(`UREG_RXDATA);
        accepted = 1'b1;
      end else begin
        accepted = 1'b0;
      end
    end
  endtask

  task drain_rx;
    input integer n;
    integer k;
    reg ok;
    begin
      for (k = 0; k < n; k = k + 1) read_rx_fc(ok);
    end
  endtask

  task clear_errors; begin m.write(`UREG_ICLR, 32'h0000_0007); end endtask

  task random_traffic;
    input integer n;
    input integer profile;
    integer t, op, r;
    reg ok;
    reg [7:0] d;
    begin
      for (t = 0; t < n; t = t + 1) begin
        r = $random(seed); if (r < 0) r = -r; op = r % 100;
        r = $random(seed); if (r < 0) r = -r; d  = r & 32'hFF;

        case (profile)
          `UPROF_REG: begin
            if      (op < 30) m.read (`UREG_STATUS);
            else if (op < 50) m.read (`UREG_CTRL);
            else if (op < 65) m.read (`UREG_ID);
            else if (op < 80) m.write(`UREG_ICLR, {29'd0, d[2:0]});
            else if (op < 90) m.write(`UREG_STATUS, {24'd0, d});
            else              m.read ({1'b1, d[6:0]});
          end

          `UPROF_TX: begin
            if      (op < 65) send_byte_fc(d, ok);
            else if (op < 85) m.read(`UREG_STATUS);
            else              m.idle(1 + (op % 6));
          end

          `UPROF_RX: begin
            if      (op < 45) recv_byte(d);
            else if (op < 75) read_rx_fc(ok);
            else if (op < 90) m.read(`UREG_STATUS);
            else              m.idle(1 + (op % 6));
          end

          default: begin
            if      (op < 22) send_byte_fc(d, ok);
            else if (op < 40) recv_byte(d);
            else if (op < 55) read_rx_fc(ok);
            else if (op < 65) m.read(`UREG_STATUS);
            else if (op < 72) m.read(`UREG_ID);
            else if (op < 80) m.write(`UREG_ICLR, {29'd0, d[2:0]});
            else if (op < 86) m.write(`UREG_RXDATA, {24'd0, d});
            else if (op < 92) m.read ({1'b1, d[6:0]});
            else              m.idle(1 + (op % 6));
          end
        endcase
      end
    end
  endtask

endmodule
