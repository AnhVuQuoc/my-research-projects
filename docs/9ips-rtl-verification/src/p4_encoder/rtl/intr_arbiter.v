`timescale 1ns/1ps

module intr_arbiter #(
  parameter N = 8
)(
  input  wire [N-1:0]        irq_i,        
  input  wire [N-1:0]        mask_i,       
  input  wire                active_i,     
  input  wire [clog2(N)-1:0] active_id_i,
  output wire [N-1:0]        pend_o,       
  output wire [clog2(N)-1:0] irq_id_o,     
  output wire                irq_vld_o,    
  output wire                any_pend_o    
);

  function integer clog2;
    input integer value;
    integer v;
    begin
      v = value - 1;
      for (clog2 = 0; v > 0; clog2 = clog2 + 1)
        v = v >> 1;
    end
  endfunction

  localparam W = clog2(N);

  assign pend_o     = irq_i & mask_i;
  assign any_pend_o = |pend_o;

  wire [W-1:0] cand_id;
  wire         cand_vld;

  prio_enc_param #(
    .N         (N),
    .MSB_FIRST (1)
  ) u_prio (
    .req_i (pend_o),
    .idx_o (cand_id),
    .vld_o (cand_vld)
  );

  wire preempt_ok = (!active_i) || (cand_id > active_id_i);

  assign irq_id_o  = cand_id;
  assign irq_vld_o = cand_vld && preempt_ok;

endmodule
