
// FIXME:
//
// Any l2 cache pipe can go to any directory (and viceversa). The reason is to
// allow a per bank SMT option (dc_pipe and l2_pipe) and to handle the TLB
// misses that can go out of bank.
//
// Effectively, a 4 pipe dual core can switch to a 8 independent l2 coherent
// cores. No need to have a switch command as the DCs and L2s are coherent.

module net_2core2dr(
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
   input                           clk
  ,input                           reset

  // c0 core L2I
  ,input  logic                    c0_l2itodr_req_valid
  ,output logic                    c0_l2itodr_req_retry
  ,input  I_l2todr_req_type        c0_l2itodr_req

  ,output logic                    c0_drtol2i_snack_valid
  ,input  logic                    c0_drtol2i_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2i_snack

  ,input                           c0_l2itodr_snoop_ack_valid
  ,output                          c0_l2itodr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       c0_l2itodr_snoop_ack

  ,input  logic                    c0_l2itodr_disp_valid
  ,output logic                    c0_l2itodr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2itodr_disp

  ,output logic                    c0_drtol2i_dack_valid
  ,input  logic                    c0_drtol2i_dack_retry
  ,output I_drtol2_dack_type       c0_drtol2i_dack

  ,input  logic                    c0_l2itodr_pfreq_valid
  ,output logic                    c0_l2itodr_pfreq_retry
  ,input  I_l2todr_pfreq_type      c0_l2itodr_pfreq

  // c0 core L2I TLB
  ,input  logic                    c0_l2ittodr_req_valid
  ,output logic                    c0_l2ittodr_req_retry
  ,input  I_l2todr_req_type        c0_l2ittodr_req

  ,output logic                    c0_drtol2it_snack_valid
  ,input  logic                    c0_drtol2it_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2it_snack

  ,input                           c0_l2ittodr_snoop_ack_valid
  ,output                          c0_l2ittodr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       c0_l2ittodr_snoop_ack

  ,input  logic                    c0_l2ittodr_disp_valid
  ,output logic                    c0_l2ittodr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2ittodr_disp

  ,output logic                    c0_drtol2it_dack_valid
  ,input  logic                    c0_drtol2it_dack_retry
  ,output I_drtol2_dack_type       c0_drtol2it_dack

  // c0 core L2D
  ,input  logic                    c0_l2d_0todr_req_valid
  ,output logic                    c0_l2d_0todr_req_retry
  ,input  I_l2todr_req_type        c0_l2d_0todr_req

  ,output logic                    c0_drtol2d_0_snack_valid
  ,input  logic                    c0_drtol2d_0_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2d_0_snack

  ,input                           c0_l2d_0todr_snoop_ack_valid
  ,output                          c0_l2d_0todr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       c0_l2d_0todr_snoop_ack

  ,input  logic                    c0_l2d_0todr_disp_valid
  ,output logic                    c0_l2d_0todr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2d_0todr_disp

  ,input  logic                    c0_drtol2d_0_dack_valid
  ,output logic                    c0_drtol2d_0_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2d_0_dack

  ,input  logic                    c0_l2d_0todr_pfreq_valid
  ,output logic                    c0_l2d_0todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      c0_l2d_0todr_pfreq

  // c0 core L2D TLB
  ,input  logic                    c0_l2dt_0todr_req_valid
  ,output logic                    c0_l2dt_0todr_req_retry
  ,input  I_l2todr_req_type        c0_l2dt_0todr_req

  ,output logic                    c0_drtol2dt_0_snack_valid
  ,input  logic                    c0_drtol2dt_0_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2dt_0_snack

  ,input                           c0_l2dt_0todr_snoop_ack_valid
  ,output                          c0_l2dt_0todr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       c0_l2dt_0todr_snoop_ack

  ,input  logic                    c0_l2dt_0todr_disp_valid
  ,output logic                    c0_l2dt_0todr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2dt_0todr_disp

  ,input  logic                    c0_drtol2dt_0_dack_valid
  ,output logic                    c0_drtol2dt_0_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2dt_0_dack

  // c1 core L2I
  ,input  logic                    c1_l2itodr_req_valid
  ,output logic                    c1_l2itodr_req_retry
  ,input  I_l2todr_req_type        c1_l2itodr_req

  ,output logic                    c1_drtol2i_snack_valid
  ,input  logic                    c1_drtol2i_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2i_snack

  ,input                           c1_l2itodr_snoop_ack_valid
  ,output                          c1_l2itodr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       c1_l2itodr_snoop_ack

  ,input  logic                    c1_l2itodr_disp_valid
  ,output logic                    c1_l2itodr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2itodr_disp

  ,input  logic                    c1_drtol2i_dack_valid
  ,output logic                    c1_drtol2i_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2i_dack

  ,input  logic                    c1_l2itodr_pfreq_valid
  ,output logic                    c1_l2itodr_pfreq_retry
  ,input  I_l2todr_pfreq_type      c1_l2itodr_pfreq

  // c1 core L2I TLB
  ,input  logic                    c1_l2ittodr_req_valid
  ,output logic                    c1_l2ittodr_req_retry
  ,input  I_l2todr_req_type        c1_l2ittodr_req

  ,output logic                    c1_drtol2it_snack_valid
  ,input  logic                    c1_drtol2it_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2it_snack

  ,input                           c1_l2ittodr_snoop_ack_valid
  ,output                          c1_l2ittodr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       c1_l2ittodr_snoop_ack

  ,input  logic                    c1_l2ittodr_disp_valid
  ,output logic                    c1_l2ittodr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2ittodr_disp

  ,input  logic                    c1_drtol2it_dack_valid
  ,output logic                    c1_drtol2it_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2it_dack

  // c1 core L2D
  ,input  logic                    c1_l2d_0todr_req_valid
  ,output logic                    c1_l2d_0todr_req_retry
  ,input  I_l2todr_req_type        c1_l2d_0todr_req

  ,output logic                    c1_drtol2d_0_snack_valid
  ,input  logic                    c1_drtol2d_0_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2d_0_snack

  ,input                           c1_l2d_0todr_snoop_ack_valid
  ,output                          c1_l2d_0todr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       c1_l2d_0todr_snoop_ack

  ,input  logic                    c1_l2d_0todr_disp_valid
  ,output logic                    c1_l2d_0todr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2d_0todr_disp

  ,input  logic                    c1_drtol2d_0_dack_valid
  ,output logic                    c1_drtol2d_0_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2d_0_dack

  ,input  logic                    c1_l2d_0todr_pfreq_valid
  ,output logic                    c1_l2d_0todr_pfreq_retry
  ,input  I_l2todr_pfreq_type      c1_l2d_0todr_pfreq

  // c1 core L2D TLB
  ,input  logic                    c1_l2dt_0todr_req_valid
  ,output logic                    c1_l2dt_0todr_req_retry
  ,input  I_l2todr_req_type        c1_l2dt_0todr_req

  ,output logic                    c1_drtol2dt_0_snack_valid
  ,input  logic                    c1_drtol2dt_0_snack_retry
  ,output I_drtol2_snack_type      c1_drtol2dt_0_snack

  ,input                           c1_l2dt_0todr_snoop_ack_valid
  ,output                          c1_l2dt_0todr_snoop_ack_retry
  ,input  I_l2snoop_ack_type       c1_l2dt_0todr_snoop_ack

  ,input  logic                    c1_l2dt_0todr_disp_valid
  ,output logic                    c1_l2dt_0todr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2dt_0todr_disp

  ,input  logic                    c1_drtol2dt_0_dack_valid
  ,output logic                    c1_drtol2dt_0_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2dt_0_dack

   // directory 0
  ,output                          l2todr0_req_valid
  ,input                           l2todr0_req_retry
  ,output I_l2todr_req_type        l2todr0_req

  ,input                           dr0tol2_snack_valid
  ,output                          dr0tol2_snack_retry
  ,input  I_drtol2_snack_type      dr0tol2_snack

  ,output                          l2todr0_disp_valid
  ,input                           l2todr0_disp_retry
  ,output I_l2todr_disp_type       l2todr0_disp

  ,input                           dr0tol2_dack_valid
  ,output                          dr0tol2_dack_retry
  ,input  I_drtol2_dack_type       dr0tol2_dack

  ,output                          l2todr0_snoop_ack_valid
  ,input                           l2todr0_snoop_ack_retry
  ,output I_drsnoop_ack_type       l2todr0_snoop_ack

  ,output logic                    l2todr0_pfreq_valid
  ,input  logic                    l2todr0_pfreq_retry
  ,output I_l2todr_pfreq_type      l2todr0_pfreq

   // directory 1
  ,output                          l2todr1_req_valid
  ,input                           l2todr1_req_retry
  ,output I_l2todr_req_type        l2todr1_req

  ,input                           dr1tol2_snack_valid
  ,output                          dr1tol2_snack_retry
  ,input  I_drtol2_snack_type      dr1tol2_snack

  ,output                          l2todr1_disp_valid
  ,input                           l2todr1_disp_retry
  ,output I_l2todr_disp_type       l2todr1_disp

  ,input                           dr1tol2_dack_valid
  ,output                          dr1tol2_dack_retry
  ,input  I_drtol2_dack_type       dr1tol2_dack

  ,output                          l2todr1_snoop_ack_valid
  ,input                           l2todr1_snoop_ack_retry
  ,output I_drsnoop_ack_type       l2todr1_snoop_ack

  ,output logic                    l2todr1_pfreq_valid
  ,input  logic                    l2todr1_pfreq_retry
  ,output I_l2todr_pfreq_type      l2todr1_pfreq

  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
  );

 // Input reqs to directory
  I_l2todr_req_type   l2todr0_req_next;
  I_l2todr_req_type   l2todr1_req_next;

  // Give some order to our valid REQ signals (add group by dr# on input, c# on output)
  // c0 l2 instruction cache
  logic c0_l2itodr0_req_valid;
  assign c0_l2itodr0_req_valid = c0_l2itodr_req_valid & ~c0_l2itodr_req.paddr[9];
  logic c0_l2itodr1_req_valid;
  assign c0_l2itodr1_req_valid = c0_l2itodr_req_valid & c0_l2itodr_req.paddr[9];
  
  // c0 l2 instruction cache tlb
  logic c0_l2ittodr0_req_valid;
  assign c0_l2ittodr0_req_valid = c0_l2ittodr_req_valid & ~c0_l2ittodr_req.paddr[9];
  logic c0_l2ittodr1_req_valid;
  assign c0_l2ittodr1_req_valid = c0_l2ittodr_req_valid & c0_l2ittodr_req.paddr[9];

  // c0 l2 data cache
  logic c0_l2d_0todr0_req_valid;
  assign c0_l2d_0todr0_req_valid = c0_l2d_0todr_req_valid & ~c0_l2d_0todr_req.paddr[9];
  logic c0_l2d_0todr1_req_valid;
  assign c0_l2d_0todr1_req_valid = c0_l2d_0todr_req_valid & c0_l2d_0todr_req.paddr[9];

  // c0 l2 data tlb
  logic c0_l2dt_0todr0_req_valid;
  assign c0_l2dt_0todr0_req_valid = c0_l2dt_0todr_req_valid & ~c0_l2dt_0todr_req.paddr[9];
  logic c0_l2dt_0todr1_req_valid;
  assign c0_l2dt_0todr1_req_valid = c0_l2dt_0todr_req_valid & c0_l2dt_0todr_req.paddr[9];

  // c1 l2 instruction cache
  logic c1_l2itodr0_req_valid;
  assign c1_l2itodr0_req_valid = c1_l2itodr_req_valid & ~c1_l2itodr_req.paddr[9];
  logic c1_l2itodr1_req_valid;
  assign c1_l2itodr1_req_valid = c1_l2itodr_req_valid & c1_l2itodr_req.paddr[9];
  
  // c1 l2 instruction cache tlb
  logic c1_l2ittodr0_req_valid;
  assign c1_l2ittodr0_req_valid = c1_l2ittodr_req_valid & ~c1_l2ittodr_req.paddr[9];
  logic c1_l2ittodr1_req_valid;
  assign c1_l2ittodr1_req_valid = c1_l2ittodr_req_valid & c1_l2ittodr_req.paddr[9];

  // c1 l2 data cache
  logic c1_l2d_0todr0_req_valid;
  assign c1_l2d_0todr0_req_valid = c1_l2d_0todr_req_valid & ~c1_l2d_0todr_req.paddr[9];
  logic c1_l2d_0todr1_req_valid;
  assign c1_l2d_0todr1_req_valid = c1_l2d_0todr_req_valid & c1_l2d_0todr_req.paddr[9];

  // c1 l2 data tlb
  logic c1_l2dt_0todr0_req_valid;
  assign c1_l2dt_0todr0_req_valid = c1_l2dt_0todr_req_valid & ~c1_l2dt_0todr_req.paddr[9];
  logic c1_l2dt_0todr1_req_valid;
  assign c1_l2dt_0todr1_req_valid = c1_l2dt_0todr_req_valid & c1_l2dt_0todr_req.paddr[9];

  logic c0_l2todr0_req_valid;
  logic c0_l2todr1_req_valid;
  logic c1_l2todr0_req_valid;
  logic c1_l2todr1_req_valid;
  logic l2todr0_req_inp_valid;
  logic l2todr1_req_inp_valid;
 
  assign c0_l2todr0_req_valid = c0_l2itodr0_req_valid|c0_l2ittodr0_req_valid|c0_l2d_0todr0_req_valid|c0_l2dt_0todr0_req_valid;
  assign c0_l2todr1_req_valid = c0_l2itodr1_req_valid|c0_l2ittodr1_req_valid|c0_l2d_0todr1_req_valid|c0_l2dt_0todr1_req_valid;
  assign c1_l2todr0_req_valid = c1_l2itodr0_req_valid|c1_l2ittodr0_req_valid|c1_l2d_0todr0_req_valid|c1_l2dt_0todr0_req_valid;
  assign c1_l2todr1_req_valid = c1_l2itodr1_req_valid|c1_l2ittodr1_req_valid|c1_l2d_0todr1_req_valid|c1_l2dt_0todr1_req_valid;
  
  assign l2todr0_req_inp_valid = c0_l2todr0_req_valid | c1_l2todr0_req_valid;
  assign l2todr1_req_inp_valid = c0_l2todr1_req_valid | c1_l2todr1_req_valid;

  logic l2todr_req_inp0_retry;
  logic l2todr_req_inp1_retry;

   //***********************REQs**********************
   // For every request if the request is valid we 
   // will pass it through. We also must set retries here.
  always_comb begin
    if (c0_l2itodr0_req_valid) begin
      l2todr0_req_next = c0_l2itodr_req;
      c0_l2itodr_req_retry = l2todr_req_inp0_retry;
    end else if (c0_l2itodr1_req_valid) begin
      c0_l2itodr_req_retry = l2todr_req_inp1_retry;
      l2todr1_req_next = c0_l2itodr_req;
    end 
  end

  always_comb begin
    if (c0_l2ittodr0_req_valid) begin
      c0_l2ittodr_req_retry = l2todr_req_inp0_retry;
      l2todr0_req_next = c0_l2ittodr_req;
    end else if (c0_l2ittodr1_req_valid) begin
      c0_l2ittodr_req_retry = l2todr_req_inp1_retry;
      l2todr1_req_next = c0_l2ittodr_req;
    end
  end

  always_comb begin
    if (c0_l2d_0todr0_req_valid) begin
      c0_l2d_0todr_req_retry = l2todr_req_inp0_retry;
      l2todr0_req_next = c0_l2d_0todr_req;
    end else if (c0_l2d_0todr1_req_valid) begin
      c0_l2d_0todr_req_retry = l2todr_req_inp1_retry;
      l2todr1_req_next = c0_l2d_0todr_req;
    end
  end

  always_comb begin
    if (c0_l2dt_0todr0_req_valid) begin
      c0_l2dt_0todr_req_retry = l2todr_req_inp0_retry;
      l2todr0_req_next = c0_l2dt_0todr_req;
    end else if (c0_l2dt_0todr1_req_valid) begin
      c0_l2dt_0todr_req_retry = l2todr_req_inp0_retry;
      l2todr0_req_next = c0_l2dt_0todr_req;
    end
  end

  always_comb begin
    if (c1_l2itodr0_req_valid) begin
      l2todr0_req_next = c1_l2itodr_req;
      c1_l2itodr_req_retry = l2todr_req_inp0_retry;
    end else if (c1_l2itodr1_req_valid) begin
      c1_l2itodr_req_retry = l2todr_req_inp1_retry;
      l2todr1_req_next = c1_l2itodr_req;
    end 
  end

  always_comb begin
    if (c1_l2ittodr0_req_valid) begin
      c1_l2ittodr_req_retry = l2todr_req_inp0_retry;
      l2todr0_req_next = c1_l2ittodr_req;
    end else if (c1_l2ittodr1_req_valid) begin
      c1_l2ittodr_req_retry = l2todr_req_inp1_retry;
      l2todr1_req_next = c1_l2ittodr_req;
    end
  end

  always_comb begin
    if (c1_l2d_0todr0_req_valid) begin
      c1_l2d_0todr_req_retry = l2todr_req_inp0_retry;
      l2todr0_req_next = c1_l2d_0todr_req;
    end else if (c1_l2d_0todr1_req_valid) begin
      c1_l2d_0todr_req_retry = l2todr_req_inp1_retry;
      l2todr1_req_next = c1_l2d_0todr_req;
    end
  end

  always_comb begin
    if (c1_l2dt_0todr0_req_valid) begin
      c1_l2dt_0todr_req_retry = l2todr_req_inp0_retry;
      l2todr0_req_next = c1_l2dt_0todr_req;
    end else if (c1_l2d_0todr1_req_valid) begin
      c1_l2dt_0todr_req_retry = l2todr_req_inp0_retry;
      l2todr0_req_next = c1_l2dt_0todr_req;
    end
  end

  fflop #(.Size($bits(I_l2todr_req_type))) req_dir0_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr0_req_next),
    .dinValid (l2todr0_req_inp_valid),
    .dinRetry (l2todr_req_inp0_retry),

    .q        (l2todr0_req),
    .qValid   (l2todr0_req_valid),
    .qRetry   (l2todr0_req_retry)
  );

  fflop #(.Size($bits(I_l2todr_req_type))) req_dir1_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr1_req_next),
    .dinValid (l2todr1_req_inp_valid),
    .dinRetry (l2todr_req_inp1_retry),

    .q        (l2todr1_req),
    .qValid   (l2todr1_req_valid),
    .qRetry   (l2todr1_req_retry)
  );

  // Input disps to directory
  I_l2todr_disp_type   l2todr0_disp_next;
  I_l2todr_disp_type   l2todr1_disp_next;

  // Give some order to our valid DISP signals (add group by dr# on input, c# on output)
  // c0 l2 instruction cache
  logic c0_l2itodr0_disp_valid;
  assign c0_l2itodr0_disp_valid = c0_l2itodr_disp_valid & ~c0_l2itodr_disp.paddr[9];
  logic c0_l2itodr1_disp_valid;
  assign c0_l2itodr1_disp_valid = c0_l2itodr_disp_valid & c0_l2itodr_disp.paddr[9];
  
  // c0 l2 instruction cache tlb
  logic c0_l2ittodr0_disp_valid;
  assign c0_l2ittodr0_disp_valid = c0_l2ittodr_disp_valid & ~c0_l2ittodr_disp.paddr[9];
  logic c0_l2ittodr1_disp_valid;
  assign c0_l2ittodr1_disp_valid = c0_l2ittodr_disp_valid & c0_l2ittodr_disp.paddr[9];

  // c0 l2 data cache
  logic c0_l2d_0todr0_disp_valid;
  assign c0_l2d_0todr0_disp_valid = c0_l2d_0todr_disp_valid & ~c0_l2d_0todr_disp.paddr[9];
  logic c0_l2d_0todr1_disp_valid;
  assign c0_l2d_0todr1_disp_valid = c0_l2d_0todr_disp_valid & c0_l2d_0todr_disp.paddr[9];

  // c0 l2 data tlb
  logic c0_l2dt_0todr0_disp_valid;
  assign c0_l2dt_0todr0_disp_valid = c0_l2dt_0todr_disp_valid & ~c0_l2dt_0todr_disp.paddr[9];
  logic c0_l2dt_0todr1_disp_valid;
  assign c0_l2dt_0todr1_disp_valid = c0_l2dt_0todr_disp_valid & c0_l2dt_0todr_disp.paddr[9];

  // c1 l2 instruction cache
  logic c1_l2itodr0_disp_valid;
  assign c1_l2itodr0_disp_valid = c1_l2itodr_disp_valid & ~c1_l2itodr_disp.paddr[9];
  logic c1_l2itodr1_disp_valid;
  assign c1_l2itodr1_disp_valid = c1_l2itodr_disp_valid & c1_l2itodr_disp.paddr[9];
  
  // c1 l2 instruction cache tlb
  logic c1_l2ittodr0_disp_valid;
  assign c1_l2ittodr0_disp_valid = c1_l2ittodr_disp_valid & ~c1_l2ittodr_disp.paddr[9];
  logic c1_l2ittodr1_disp_valid;
  assign c1_l2ittodr1_disp_valid = c1_l2ittodr_disp_valid & c1_l2ittodr_disp.paddr[9];

  // c1 l2 data cache
  logic c1_l2d_0todr0_disp_valid;
  assign c1_l2d_0todr0_disp_valid = c1_l2d_0todr_disp_valid & ~c1_l2d_0todr_disp.paddr[9];
  logic c1_l2d_0todr1_disp_valid;
  assign c1_l2d_0todr1_disp_valid = c1_l2d_0todr_disp_valid & c1_l2d_0todr_disp.paddr[9];

  // c1 l2 data tlb
  logic c1_l2dt_0todr0_disp_valid;
  assign c1_l2dt_0todr0_disp_valid = c1_l2dt_0todr_disp_valid & ~c1_l2dt_0todr_disp.paddr[9];
  logic c1_l2dt_0todr1_disp_valid;
  assign c1_l2dt_0todr1_disp_valid = c1_l2dt_0todr_disp_valid & c1_l2dt_0todr_disp.paddr[9];

  logic c0_l2todr0_disp_valid;
  logic c0_l2todr1_disp_valid;
  logic c1_l2todr0_disp_valid;
  logic c1_l2todr1_disp_valid;
  logic l2todr0_disp_inp_valid;
  logic l2todr1_disp_inp_valid;

  assign c0_l2todr0_disp_valid = c0_l2itodr0_disp_valid|c0_l2ittodr0_disp_valid|c0_l2d_0todr0_disp_valid|c0_l2dt_0todr0_disp_valid;
  assign c0_l2todr1_disp_valid = c0_l2itodr1_disp_valid|c0_l2ittodr1_disp_valid|c0_l2d_0todr1_disp_valid|c0_l2dt_0todr1_disp_valid;
  assign c1_l2todr0_disp_valid = c1_l2itodr0_disp_valid|c1_l2ittodr0_disp_valid|c1_l2d_0todr0_disp_valid|c1_l2dt_0todr0_disp_valid;
  assign c1_l2todr1_disp_valid = c1_l2itodr1_disp_valid|c1_l2ittodr1_disp_valid|c1_l2d_0todr1_disp_valid|c1_l2dt_0todr1_disp_valid;
  
  assign l2todr0_disp_inp_valid = c0_l2todr0_disp_valid | c1_l2todr0_disp_valid;
  assign l2todr1_disp_inp_valid = c0_l2todr1_disp_valid | c1_l2todr1_disp_valid;

  logic l2todr_disp_inp0_retry;
  logic l2todr_disp_inp1_retry;

  //***********************disps**********************
  // For every disp if the disp is valid we 
  // will pass it through. We also must set retries here.
  always_comb begin
    if (c0_l2itodr0_disp_valid) begin
      l2todr0_disp_next = c0_l2itodr_disp;
      c0_l2itodr_disp_retry = l2todr_disp_inp0_retry;
    end else if (c0_l2itodr1_disp_valid) begin
      c0_l2itodr_disp_retry = l2todr_disp_inp1_retry;
      l2todr1_disp_next = c0_l2itodr_disp;
    end 
  end

  always_comb begin
    if (c0_l2ittodr0_disp_valid) begin
      c0_l2ittodr_disp_retry = l2todr_disp_inp0_retry;
      l2todr0_disp_next = c0_l2ittodr_disp;
    end else if (c0_l2ittodr1_disp_valid) begin
      c0_l2ittodr_disp_retry = l2todr_disp_inp1_retry;
      l2todr1_disp_next = c0_l2ittodr_disp;
    end
  end

  always_comb begin
    if (c0_l2d_0todr0_disp_valid) begin
      c0_l2d_0todr_disp_retry = l2todr_disp_inp0_retry;
      l2todr0_disp_next = c0_l2d_0todr_disp;
    end else if (c0_l2d_0todr1_disp_valid) begin
      c0_l2d_0todr_disp_retry = l2todr_disp_inp1_retry;
      l2todr1_disp_next = c0_l2d_0todr_disp;
    end
  end

  always_comb begin
    if (c0_l2dt_0todr0_disp_valid) begin
      c0_l2dt_0todr_disp_retry = l2todr_disp_inp0_retry;
      l2todr0_disp_next = c0_l2dt_0todr_disp;
    end else if (c0_l2dt_0todr1_disp_valid) begin
      c0_l2dt_0todr_disp_retry = l2todr_disp_inp0_retry;
      l2todr0_disp_next = c0_l2dt_0todr_disp;
    end
  end

  always_comb begin
    if (c1_l2itodr0_disp_valid) begin
      l2todr0_disp_next = c1_l2itodr_disp;
      c1_l2itodr_disp_retry = l2todr_disp_inp0_retry;
    end else if (c1_l2itodr1_disp_valid) begin
      c1_l2itodr_disp_retry = l2todr_disp_inp1_retry;
      l2todr1_disp_next = c1_l2itodr_disp;
    end 
  end

  always_comb begin
    if (c1_l2ittodr0_disp_valid) begin
      c1_l2ittodr_disp_retry = l2todr_disp_inp0_retry;
      l2todr0_disp_next = c1_l2ittodr_disp;
    end else if (c1_l2ittodr1_disp_valid) begin
      c1_l2ittodr_disp_retry = l2todr_disp_inp1_retry;
      l2todr1_disp_next = c1_l2ittodr_disp;
    end
  end

  always_comb begin
    if (c1_l2d_0todr0_disp_valid) begin
      c1_l2d_0todr_disp_retry = l2todr_disp_inp0_retry;
      l2todr0_disp_next = c1_l2d_0todr_disp;
    end else if (c1_l2d_0todr1_disp_valid) begin
      c1_l2d_0todr_disp_retry = l2todr_disp_inp1_retry;
      l2todr1_disp_next = c1_l2d_0todr_disp;
    end
  end

  always_comb begin
    if (c1_l2dt_0todr0_disp_valid) begin
      c1_l2dt_0todr_disp_retry = l2todr_disp_inp0_retry;
      l2todr0_disp_next = c1_l2dt_0todr_disp;
    end else if (c1_l2d_0todr1_disp_valid) begin
      c1_l2dt_0todr_disp_retry = l2todr_disp_inp0_retry;
      l2todr0_disp_next = c1_l2dt_0todr_disp;
    end
  end

  fflop #(.Size($bits(I_l2todr_disp_type))) disp_dir0_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr0_disp_next),
    .dinValid (l2todr0_disp_inp_valid),
    .dinRetry (l2todr_disp_inp0_retry),

    .q        (l2todr0_disp),
    .qValid   (l2todr0_disp_valid),
    .qRetry   (l2todr0_disp_retry)
  );

  fflop #(.Size($bits(I_l2todr_disp_type))) disp_dir1_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr1_disp_next),
    .dinValid (l2todr1_disp_inp_valid),
    .dinRetry (l2todr_disp_inp1_retry),

    .q        (l2todr1_disp),
    .qValid   (l2todr1_disp_valid),
    .qRetry   (l2todr1_disp_retry)
  );

  // Input pfreqs to directory
  I_l2todr_pfreq_type   l2todr0_pfreq_next;
  I_l2todr_pfreq_type   l2todr1_pfreq_next;

  // Give some order to our valid pfreq signals (add group by dr# on input, c# on output)
  // c0 l2 instruction cache
  logic c0_l2itodr0_pfreq_valid;
  assign c0_l2itodr0_pfreq_valid = c0_l2itodr_pfreq_valid & ~c0_l2itodr_pfreq.paddr[9];
  logic c0_l2itodr1_pfreq_valid;
  assign c0_l2itodr1_pfreq_valid = c0_l2itodr_pfreq_valid & c0_l2itodr_pfreq.paddr[9];

  // c0 l2 data cache
  logic c0_l2d_0todr0_pfreq_valid;
  assign c0_l2d_0todr0_pfreq_valid = c0_l2d_0todr_pfreq_valid & ~c0_l2d_0todr_pfreq.paddr[9];
  logic c0_l2d_0todr1_pfreq_valid;
  assign c0_l2d_0todr1_pfreq_valid = c0_l2d_0todr_pfreq_valid & c0_l2d_0todr_pfreq.paddr[9];

  // c1 l2 instruction cache
  logic c1_l2itodr0_pfreq_valid;
  assign c1_l2itodr0_pfreq_valid = c1_l2itodr_pfreq_valid & ~c1_l2itodr_pfreq.paddr[9];
  logic c1_l2itodr1_pfreq_valid;
  assign c1_l2itodr1_pfreq_valid = c1_l2itodr_pfreq_valid & c1_l2itodr_pfreq.paddr[9];

  // c1 l2 data cache
  logic c1_l2d_0todr0_pfreq_valid;
  assign c1_l2d_0todr0_pfreq_valid = c1_l2d_0todr_pfreq_valid & ~c1_l2d_0todr_pfreq.paddr[9];
  logic c1_l2d_0todr1_pfreq_valid;
  assign c1_l2d_0todr1_pfreq_valid = c1_l2d_0todr_pfreq_valid & c1_l2d_0todr_pfreq.paddr[9];

  logic c0_l2todr0_pfreq_valid;
  logic c0_l2todr1_pfreq_valid;
  logic c1_l2todr0_pfreq_valid;
  logic c1_l2todr1_pfreq_valid;
  logic l2todr0_pfreq_inp_valid;
  logic l2todr1_pfreq_inp_valid;

  assign c0_l2todr0_pfreq_valid = c0_l2itodr0_pfreq_valid|c0_l2d_0todr0_pfreq_valid;
  assign c0_l2todr1_pfreq_valid = c0_l2itodr1_pfreq_valid|c0_l2d_0todr1_pfreq_valid;
  assign c1_l2todr0_pfreq_valid = c1_l2itodr0_pfreq_valid|c1_l2d_0todr0_pfreq_valid;
  assign c1_l2todr1_pfreq_valid = c1_l2itodr1_pfreq_valid|c1_l2d_0todr1_pfreq_valid;
  
  assign l2todr0_pfreq_inp_valid = c0_l2todr0_pfreq_valid | c1_l2todr0_pfreq_valid;
  assign l2todr1_pfreq_inp_valid = c0_l2todr1_pfreq_valid | c1_l2todr1_pfreq_valid;

  logic l2todr_pfreq_inp0_retry;
  logic l2todr_pfreq_inp1_retry;

  //***********************pfreqs**********************
  // For every pfreq if the pfreq is valid we 
  // will pass it through. We also must set retries here.

  always_comb begin
    if (c0_l2itodr0_pfreq_valid) begin
      l2todr0_pfreq_next = c0_l2itodr_pfreq;
      c0_l2itodr_pfreq_retry = l2todr_pfreq_inp0_retry;
    end else if (c0_l2itodr1_pfreq_valid) begin
      c0_l2itodr_pfreq_retry = l2todr_pfreq_inp1_retry;
      l2todr1_pfreq_next = c0_l2itodr_pfreq;
    end 
  end

  always_comb begin
    if (c0_l2d_0todr0_pfreq_valid) begin
      c0_l2d_0todr_pfreq_retry = l2todr_pfreq_inp0_retry;
      l2todr0_pfreq_next = c0_l2d_0todr_pfreq;
    end else if (c0_l2d_0todr1_pfreq_valid) begin
      c0_l2d_0todr_pfreq_retry = l2todr_pfreq_inp1_retry;
      l2todr1_pfreq_next = c0_l2d_0todr_pfreq;
    end
  end

  always_comb begin
    if (c1_l2itodr0_pfreq_valid) begin
      l2todr0_pfreq_next = c1_l2itodr_pfreq;
      c1_l2itodr_pfreq_retry = l2todr_pfreq_inp0_retry;
    end else if (c1_l2itodr1_pfreq_valid) begin
      c1_l2itodr_pfreq_retry = l2todr_pfreq_inp1_retry;
      l2todr1_pfreq_next = c1_l2itodr_pfreq;
    end 
  end

  always_comb begin
    if (c1_l2d_0todr0_pfreq_valid) begin
      c1_l2d_0todr_pfreq_retry = l2todr_pfreq_inp0_retry;
      l2todr0_pfreq_next = c1_l2d_0todr_pfreq;
    end else if (c1_l2d_0todr1_pfreq_valid) begin
      c1_l2d_0todr_pfreq_retry = l2todr_pfreq_inp1_retry;
      l2todr1_pfreq_next = c1_l2d_0todr_pfreq;
    end
  end

  fflop #(.Size($bits(I_l2todr_pfreq_type))) pfreq_dir0_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr0_pfreq_next),
    .dinValid (l2todr0_pfreq_inp_valid),
    .dinRetry (l2todr_pfreq_inp0_retry),

    .q        (l2todr0_pfreq),
    .qValid   (l2todr0_pfreq_valid),
    .qRetry   (l2todr0_pfreq_retry)
  );

  fflop #(.Size($bits(I_l2todr_pfreq_type))) pfreq_dir1_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr1_pfreq_next),
    .dinValid (l2todr1_pfreq_inp_valid),
    .dinRetry (l2todr_pfreq_inp1_retry),

    .q        (l2todr1_pfreq),
    .qValid   (l2todr1_pfreq_valid),
    .qRetry   (l2todr1_pfreq_retry)
  );

 // Input snoop_acks to directory
  I_l2snoop_ack_type   l2todr0_snoop_ack_next;
  I_l2snoop_ack_type   l2todr1_snoop_ack_next;

  // Give some order to our valid snoop_ack signals (add group by dr# on input, c# on output)
  // c0 l2 instruction cache
  logic c0_l2itodr0_snoop_ack_valid;
  assign c0_l2itodr0_snoop_ack_valid = c0_l2itodr_snoop_ack_valid & ~c0_l2itodr_snoop_ack.directory_id[0];
  logic c0_l2itodr1_snoop_ack_valid;
  assign c0_l2itodr1_snoop_ack_valid = c0_l2itodr_snoop_ack_valid & c0_l2itodr_snoop_ack.directory_id[0];
  
  // c0 l2 instruction cache tlb
  logic c0_l2ittodr0_snoop_ack_valid;
  assign c0_l2ittodr0_snoop_ack_valid = c0_l2ittodr_snoop_ack_valid & ~c0_l2ittodr_snoop_ack.directory_id[0];
  logic c0_l2ittodr1_snoop_ack_valid;
  assign c0_l2ittodr1_snoop_ack_valid = c0_l2ittodr_snoop_ack_valid & c0_l2ittodr_snoop_ack.directory_id[0];

  // c0 l2 data cache
  logic c0_l2d_0todr0_snoop_ack_valid;
  assign c0_l2d_0todr0_snoop_ack_valid = c0_l2d_0todr_snoop_ack_valid & ~c0_l2d_0todr_snoop_ack.directory_id[0];
  logic c0_l2d_0todr1_snoop_ack_valid;
  assign c0_l2d_0todr1_snoop_ack_valid = c0_l2d_0todr_snoop_ack_valid & c0_l2d_0todr_snoop_ack.directory_id[0];

  // c0 l2 data tlb
  logic c0_l2dt_0todr0_snoop_ack_valid;
  assign c0_l2dt_0todr0_snoop_ack_valid = c0_l2dt_0todr_snoop_ack_valid & ~c0_l2dt_0todr_snoop_ack.directory_id[0];
  logic c0_l2dt_0todr1_snoop_ack_valid;
  assign c0_l2dt_0todr1_snoop_ack_valid = c0_l2dt_0todr_snoop_ack_valid & c0_l2dt_0todr_snoop_ack.directory_id[0];

  // c1 l2 instruction cache
  logic c1_l2itodr0_snoop_ack_valid;
  assign c1_l2itodr0_snoop_ack_valid = c1_l2itodr_snoop_ack_valid & ~c1_l2itodr_snoop_ack.directory_id[0];
  logic c1_l2itodr1_snoop_ack_valid;
  assign c1_l2itodr1_snoop_ack_valid = c1_l2itodr_snoop_ack_valid & c1_l2itodr_snoop_ack.directory_id[0];
  
  // c1 l2 instruction cache tlb
  logic c1_l2ittodr0_snoop_ack_valid;
  assign c1_l2ittodr0_snoop_ack_valid = c1_l2ittodr_snoop_ack_valid & ~c1_l2ittodr_snoop_ack.directory_id[0];
  logic c1_l2ittodr1_snoop_ack_valid;
  assign c1_l2ittodr1_snoop_ack_valid = c1_l2ittodr_snoop_ack_valid & c1_l2ittodr_snoop_ack.directory_id[0];

  // c1 l2 data cache
  logic c1_l2d_0todr0_snoop_ack_valid;
  assign c1_l2d_0todr0_snoop_ack_valid = c1_l2d_0todr_snoop_ack_valid & ~c1_l2d_0todr_snoop_ack.directory_id[0];
  logic c1_l2d_0todr1_snoop_ack_valid;
  assign c1_l2d_0todr1_snoop_ack_valid = c1_l2d_0todr_snoop_ack_valid & c1_l2d_0todr_snoop_ack.directory_id[0];

  // c1 l2 data tlb
  logic c1_l2dt_0todr0_snoop_ack_valid;
  assign c1_l2dt_0todr0_snoop_ack_valid = c1_l2dt_0todr_snoop_ack_valid & ~c1_l2dt_0todr_snoop_ack.directory_id[0];
  logic c1_l2dt_0todr1_snoop_ack_valid;
  assign c1_l2dt_0todr1_snoop_ack_valid = c1_l2dt_0todr_snoop_ack_valid & c1_l2dt_0todr_snoop_ack.directory_id[0];

  logic c0_l2todr0_snoop_ack_valid;
  logic c0_l2todr1_snoop_ack_valid;
  logic c1_l2todr0_snoop_ack_valid;
  logic c1_l2todr1_snoop_ack_valid;
  logic l2todr0_snoop_ack_inp_valid;
  logic l2todr1_snoop_ack_inp_valid;
 
  assign c0_l2todr0_snoop_ack_valid = c0_l2itodr0_snoop_ack_valid|c0_l2ittodr0_snoop_ack_valid|c0_l2d_0todr0_snoop_ack_valid|c0_l2dt_0todr0_snoop_ack_valid;
  assign c0_l2todr1_snoop_ack_valid = c0_l2itodr1_snoop_ack_valid|c0_l2ittodr1_snoop_ack_valid|c0_l2d_0todr1_snoop_ack_valid|c0_l2dt_0todr1_snoop_ack_valid;
  assign c1_l2todr0_snoop_ack_valid = c1_l2itodr0_snoop_ack_valid|c1_l2ittodr0_snoop_ack_valid|c1_l2d_0todr0_snoop_ack_valid|c1_l2dt_0todr0_snoop_ack_valid;
  assign c1_l2todr1_snoop_ack_valid = c1_l2itodr1_snoop_ack_valid|c1_l2ittodr1_snoop_ack_valid|c1_l2d_0todr1_snoop_ack_valid|c1_l2dt_0todr1_snoop_ack_valid;
  
  assign l2todr0_snoop_ack_inp_valid = c0_l2todr0_snoop_ack_valid | c1_l2todr0_snoop_ack_valid;
  assign l2todr1_snoop_ack_inp_valid = c0_l2todr1_snoop_ack_valid | c1_l2todr1_snoop_ack_valid;

  logic l2todr_snoop_ack_inp0_retry;
  logic l2todr_snoop_ack_inp1_retry;
   //***********************snoop_acks**********************
  always_comb begin
    if (c0_l2itodr0_snoop_ack_valid) begin
      l2todr0_snoop_ack_next = c0_l2itodr_snoop_ack;
      c0_l2itodr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
    end else if (c0_l2itodr1_snoop_ack_valid) begin
      c0_l2itodr_snoop_ack_retry = l2todr_snoop_ack_inp1_retry;
      l2todr1_snoop_ack_next = c0_l2itodr_snoop_ack;
    end 
  end

  always_comb begin
    if (c0_l2ittodr0_snoop_ack_valid) begin
      c0_l2ittodr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
      l2todr0_snoop_ack_next = c0_l2ittodr_snoop_ack;
    end else if (c0_l2ittodr1_snoop_ack_valid) begin
      c0_l2ittodr_snoop_ack_retry = l2todr_snoop_ack_inp1_retry;
      l2todr1_snoop_ack_next = c0_l2ittodr_snoop_ack;
    end
  end

  always_comb begin
    if (c0_l2d_0todr0_snoop_ack_valid) begin
      c0_l2d_0todr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
      l2todr0_snoop_ack_next = c0_l2d_0todr_snoop_ack;
    end else if (c0_l2d_0todr1_snoop_ack_valid) begin
      c0_l2d_0todr_snoop_ack_retry = l2todr_snoop_ack_inp1_retry;
      l2todr1_snoop_ack_next = c0_l2d_0todr_snoop_ack;
    end
  end

  always_comb begin
    if (c0_l2dt_0todr0_snoop_ack_valid) begin
      c0_l2dt_0todr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
      l2todr0_snoop_ack_next = c0_l2dt_0todr_snoop_ack;
    end else if (c0_l2dt_0todr1_snoop_ack_valid) begin
      c0_l2dt_0todr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
      l2todr0_snoop_ack_next = c0_l2dt_0todr_snoop_ack;
    end
  end

  always_comb begin
    if (c1_l2itodr0_snoop_ack_valid) begin
      l2todr0_snoop_ack_next = c1_l2itodr_snoop_ack;
      c1_l2itodr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
    end else if (c1_l2itodr1_snoop_ack_valid) begin
      c1_l2itodr_snoop_ack_retry = l2todr_snoop_ack_inp1_retry;
      l2todr1_snoop_ack_next = c1_l2itodr_snoop_ack;
    end 
  end

  always_comb begin
    if (c1_l2ittodr0_snoop_ack_valid) begin
      c1_l2ittodr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
      l2todr0_snoop_ack_next = c1_l2ittodr_snoop_ack;
    end else if (c1_l2ittodr1_snoop_ack_valid) begin
      c1_l2ittodr_snoop_ack_retry = l2todr_snoop_ack_inp1_retry;
      l2todr1_snoop_ack_next = c1_l2ittodr_snoop_ack;
    end
  end

  always_comb begin
    if (c1_l2d_0todr0_snoop_ack_valid) begin
      c1_l2d_0todr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
      l2todr0_snoop_ack_next = c1_l2d_0todr_snoop_ack;
    end else if (c1_l2d_0todr1_snoop_ack_valid) begin
      c1_l2d_0todr_snoop_ack_retry = l2todr_snoop_ack_inp1_retry;
      l2todr1_snoop_ack_next = c1_l2d_0todr_snoop_ack;
    end
  end

  always_comb begin
    if (c1_l2dt_0todr0_snoop_ack_valid) begin
      c1_l2dt_0todr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
      l2todr0_snoop_ack_next = c1_l2dt_0todr_snoop_ack;
    end else if (c1_l2d_0todr1_snoop_ack_valid) begin
      c1_l2dt_0todr_snoop_ack_retry = l2todr_snoop_ack_inp0_retry;
      l2todr0_snoop_ack_next = c1_l2dt_0todr_snoop_ack;
    end
  end

  fflop #(.Size($bits(I_drsnoop_ack_type))) snoop_ack_dir0_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr0_snoop_ack_next),
    .dinValid (l2todr0_snoop_ack_inp_valid),
    .dinRetry (l2todr_snoop_ack_inp0_retry),

    .q        (l2todr0_snoop_ack),
    .qValid   (l2todr0_snoop_ack_valid),
    .qRetry   (l2todr0_snoop_ack_retry)
  );

  fflop #(.Size($bits(I_drsnoop_ack_type))) snoop_ack_dir1_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr1_snoop_ack_next),
    .dinValid (l2todr1_snoop_ack_inp_valid),
    .dinRetry (l2todr_snoop_ack_inp1_retry),

    .q        (l2todr1_snoop_ack),
    .qValid   (l2todr1_snoop_ack_valid),
    .qRetry   (l2todr1_snoop_ack_retry)
  );

  I_drtol2_snack_type c0_drtol2i_snack_next;
  I_drtol2_snack_type c0_drtol2it_snack_next;
  I_drtol2_snack_type c0_drtol2d_0_snack_next;
  I_drtol2_snack_type c0_drtol2dt_0_snack_next;
  I_drtol2_snack_type c1_drtol2i_snack_next;
  I_drtol2_snack_type c1_drtol2it_snack_next;
  I_drtol2_snack_type c1_drtol2d_0_snack_next;
  I_drtol2_snack_type c1_drtol2dt_0_snack_next;

  always_comb begin
    if (dr0tol2_snack_valid) begin
      if(dr0tol2_snack.nid[0]) begin // nid 0 -> c0, nid 1 -> c1
        case(dr0tol2_snack.l2id[1:0])
          2'b00: begin
            c0_drtol2i_snack_next = dr0tol2_snack;
            dr0tol2_snack_retry = c0_drtol2i_snack_retry;
          end
          2'b01: begin
            c0_drtol2it_snack_next = dr0tol2_snack;
            dr0tol2_snack_retry = c0_drtol2it_snack_retry;
          end
          2'b10: begin
            c0_drtol2d_0_snack_next = dr0tol2_snack;
            dr0tol2_snack_retry = c0_drtol2d_0_snack_retry;
          end
          2'b11: begin
            dr0tol2_snack_retry = c0_drtol2dt_0_snack_retry;
            c0_drtol2dt_0_snack_next = dr0tol2_snack;
          end
        endcase
      end else begin
        case(dr0tol2_snack.l2id[1:0])
          2'b00: begin
            c1_drtol2i_snack_next = dr0tol2_snack;
            dr0tol2_snack_retry = c1_drtol2i_snack_retry;
            end
          2'b01: begin
            c1_drtol2it_snack_next = dr0tol2_snack;
            dr0tol2_snack_retry = c1_drtol2it_snack_retry;
            end
          2'b10: begin
            c1_drtol2d_0_snack_next = dr0tol2_snack;
            dr0tol2_snack_retry = c1_drtol2d_0_snack_retry;
            end
          2'b11: begin
            dr0tol2_snack_retry = c1_drtol2dt_0_snack_retry;
            c1_drtol2dt_0_snack_next = dr0tol2_snack;
            end
        endcase
      end
    end
  end


  fflop #(.Size($bits(I_drtol2_snack_type))) c0_drtol2i_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (c0_drtol2i_snack_next),
    .dinValid (dr0tol2_snack_valid),
    .dinRetry (dr0tol2_snack_retry),

    .q        (c0_drtol2i_snack),
    .qValid   (c0_drtol2i_snack_valid),
    .qRetry   (c0_drtol2i_snack_retry)
  );

  fflop #(.Size($bits(I_drtol2_snack_type))) c0_drtol2it_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (c0_drtol2it_snack_next),
    .dinValid (dr0tol2_snack_valid),
    .dinRetry (dr0tol2_snack_retry),

    .q        (c0_drtol2it_snack),
    .qValid   (c0_drtol2it_snack_valid),
    .qRetry   (c0_drtol2it_snack_retry)
  );

  fflop #(.Size($bits(I_drtol2_snack_type))) c0_drtol2d_0_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (c0_drtol2d_0_snack_next),
    .dinValid (dr0tol2_snack_valid),
    .dinRetry (dr0tol2_snack_retry),

    .q        (c0_drtol2d_0_snack),
    .qValid   (c0_drtol2d_0_snack_valid),
    .qRetry   (c0_drtol2d_0_snack_retry)
  );

  fflop #(.Size($bits(I_drtol2_snack_type))) c0_drtol2dt_0_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (c0_drtol2dt_0_snack_next),
    .dinValid (dr0tol2_snack_valid),
    .dinRetry (dr0tol2_snack_retry),

    .q        (c0_drtol2dt_0_snack),
    .qValid   (c0_drtol2dt_0_snack_valid),
    .qRetry   (c0_drtol2dt_0_snack_retry)
  );

  fflop #(.Size($bits(I_drtol2_snack_type))) c1_drtol2i_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (c1_drtol2i_snack_next),
    .dinValid (dr0tol2_snack_valid),
    .dinRetry (dr0tol2_snack_retry),

    .q        (c1_drtol2i_snack),
    .qValid   (c1_drtol2i_snack_valid),
    .qRetry   (c1_drtol2i_snack_retry)
  );

  fflop #(.Size($bits(I_drtol2_snack_type))) c1_drtol2it_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (c1_drtol2it_snack_next),
    .dinValid (dr0tol2_snack_valid),
    .dinRetry (dr0tol2_snack_retry),

    .q        (c1_drtol2it_snack),
    .qValid   (c1_drtol2it_snack_valid),
    .qRetry   (c1_drtol2it_snack_retry)
  );

  fflop #(.Size($bits(I_drtol2_snack_type))) c1_drtol2d_0_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (c1_drtol2d_0_snack_next),
    .dinValid (dr0tol2_snack_valid),
    .dinRetry (dr0tol2_snack_retry),

    .q        (c1_drtol2d_0_snack),
    .qValid   (c1_drtol2d_0_snack_valid),
    .qRetry   (c1_drtol2d_0_snack_retry)
  );

  fflop #(.Size($bits(I_drtol2_snack_type))) c1_drtol2dt_0_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (c1_drtol2dt_0_snack_next),
    .dinValid (dr0tol2_snack_valid),
    .dinRetry (dr0tol2_snack_retry),

    .q        (c1_drtol2dt_0_snack),
    .qValid   (c1_drtol2dt_0_snack_valid),
    .qRetry   (c1_drtol2dt_0_snack_retry)
  );
/*
  always_comb begin
    if (dr1tol2_snack_valid) begin
      
    end
  end
  */
endmodule