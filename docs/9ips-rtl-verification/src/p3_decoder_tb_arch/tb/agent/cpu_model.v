`timescale 1ns/1ps
`include "tb_defs.vh"

module cpu_model (
  input  wire           clk,
  input  wire           rst_n,
  input  wire           drv_rdy_i,
  output reg            cpu_vld_o,
  output reg [`AW-1:0]  cpu_addr_o
);

  integer seed;
  integer n_sent;

  initial begin
    seed       = 32'hCAFE_0001;
    n_sent     = 0;
    cpu_vld_o  = 1'b0;
    cpu_addr_o = {`AW{1'b0}};
  end

  task set_seed;
    input [31:0] s;
    begin
      seed = s;
    end
  endtask

  task send;
    input [`AW-1:0] a;
    begin
      @(negedge clk);
      while (!drv_rdy_i) @(negedge clk);   
      cpu_addr_o = a;
      cpu_vld_o  = 1'b1;
      n_sent     = n_sent + 1;
    end
  endtask

  task stop;                               
    begin
      @(negedge clk);
      cpu_vld_o = 1'b0;
    end
  endtask

  task idle;                               
    input integer n;
    integer k;
    begin
      @(negedge clk);
      cpu_vld_o = 1'b0;
      for (k = 0; k < n; k = k + 1) @(negedge clk);
    end
  endtask

  task burst;                     
    input [`AW-1:0] start;
    input integer   n;
    input integer   stride;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1)
        send(start + k*stride);
      stop;
    end
  endtask

  task walk_boundaries;            
    input [`AW-1:0] base;
    input [`AW-1:0] size;
    begin
      send(base);
      send(base + size - 1);
      send(base + (size >> 1));
      send(base - 1);
      send(base + size);
      stop;
    end
  endtask

  task random_uniform;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1)
        send($random(seed));
      stop;
    end
  endtask


  task random_biased;
    input integer n;
    integer k, r, which;
    reg [`AW-1:0] b, s;
    begin
      for (k = 0; k < n; k = k + 1) begin
        r = {$random(seed)} % 4;
        case (r)
          0: begin b = `BASE0; s = `SIZE0; end
          1: begin b = `BASE1; s = `SIZE1; end
          2: begin b = `BASE2; s = `SIZE2; end
          default: begin b = `BASE3; s = `SIZE3; end
        endcase
        which = {$random(seed)} % 3;
        case (which)
          0      : send(b + ({$random(seed)} % 33) - 16);       
          1      : send(b + s - 16 + ({$random(seed)} % 33));    
          default: send(b + ({$random(seed)} % s));            
        endcase
      end
      stop;
    end
  endtask


  task cpu_traffic;
    input integer n;
    integer k, r;
    reg [`AW-1:0] pc;
    begin
      pc = `BASE0;
      for (k = 0; k < n; k = k + 1) begin
        r = {$random(seed)} % 1000;
        if (r < 3) begin
          send($random(seed));
        end else if (r < 23) begin
          if (r[0]) send(`BASE2 + (({$random(seed)} % (`SIZE2 >> 2)) << 2));
          else      send(`BASE3 + (({$random(seed)} % (`SIZE3 >> 2)) << 2));
        end else if (r < 130) begin
          send(`BASE1 + (({$random(seed)} % (`SIZE1 >> 2)) << 2));
        end else begin
          send(pc);
          if (({$random(seed)} % 100) < 8)
            pc = `BASE0 + (({$random(seed)} % (`SIZE0 >> 2)) << 2);
          else
            pc = pc + 4;
          if (pc >= (`BASE0 + `SIZE0)) pc = `BASE0;                
        end
      end
      stop;
    end
  endtask

  task run_pattern;
    input integer pat;
    input integer n;
    begin
      case (pat)
        `PAT_LINEAR   : burst(`BASE0, n, 4);
        `PAT_BOUNDARY : begin
                          walk_boundaries(`BASE0, `SIZE0);
                          walk_boundaries(`BASE1, `SIZE1);
                          walk_boundaries(`BASE2, `SIZE2);
                          walk_boundaries(`BASE3, `SIZE3);
                        end
        `PAT_RANDOM   : random_uniform(n);
        `PAT_BIASED   : random_biased(n);
        `PAT_REALISTIC: cpu_traffic(n);
        default       : random_uniform(n);
      endcase
    end
  endtask

endmodule
