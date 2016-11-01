
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

  ,output                          c0_l2itodr_snoop_ack_valid
  ,input                           c0_l2itodr_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_l2itodr_snoop_ack

  ,input  logic                    c0_l2itodr_disp_valid
  ,output logic                    c0_l2itodr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2itodr_disp

  ,input  logic                    c0_drtol2i_dack_valid
  ,output logic                    c0_drtol2i_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2i_dack

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

  ,output                          c0_l2ittodr_snoop_ack_valid
  ,input                           c0_l2ittodr_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_l2ittodr_snoop_ack

  ,input  logic                    c0_l2ittodr_disp_valid
  ,output logic                    c0_l2ittodr_disp_retry
  ,input  I_l2todr_disp_type       c0_l2ittodr_disp

  ,input  logic                    c0_drtol2it_dack_valid
  ,output logic                    c0_drtol2it_dack_retry
  ,input  I_drtol2_dack_type       c0_drtol2it_dack

  // c0 core L2D
  ,input  logic                    c0_l2d_0todr_req_valid
  ,output logic                    c0_l2d_0todr_req_retry
  ,input  I_l2todr_req_type        c0_l2d_0todr_req

  ,output logic                    c0_drtol2d_0_snack_valid
  ,input  logic                    c0_drtol2d_0_snack_retry
  ,output I_drtol2_snack_type      c0_drtol2d_0_snack

  ,output                          c0_l2d_0todr_snoop_ack_valid
  ,input                           c0_l2d_0todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_l2d_0todr_snoop_ack

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

  ,output                          c0_l2dt_0todr_snoop_ack_valid
  ,input                           c0_l2dt_0todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       c0_l2dt_0todr_snoop_ack

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

  ,output                          c1_l2itodr_snoop_ack_valid
  ,input                           c1_l2itodr_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_l2itodr_snoop_ack

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

  ,output                          c1_l2ittodr_snoop_ack_valid
  ,input                           c1_l2ittodr_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_l2ittodr_snoop_ack

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

  ,output                          c1_l2d_0todr_snoop_ack_valid
  ,input                           c1_l2d_0todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_l2d_0todr_snoop_ack

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

  ,output                          c1_l2dt_0todr_snoop_ack_valid
  ,input                           c1_l2dt_0todr_snoop_ack_retry
  ,output I_l2snoop_ack_type       c1_l2dt_0todr_snoop_ack

  ,input  logic                    c1_l2dt_0todr_disp_valid
  ,output logic                    c1_l2dt_0todr_disp_retry
  ,input  I_l2todr_disp_type       c1_l2dt_0todr_disp

  ,input  logic                    c1_drtol2dt_0_dack_valid
  ,output logic                    c1_drtol2dt_0_dack_retry
  ,input  I_drtol2_dack_type       c1_drtol2dt_0_dack

   // directory 0
  ,output                          l2todr0_req_valid
  ,input                           l2todr0_req_retry
  ,output  I_l2todr_req_type       l2todr0_req

  ,input                           dr0tol2_snack_valid
  ,output                          dr0tol2_snack_retry
  ,input I_drtol2_snack_type       dr0tol2_snack

  ,output                          l2todr0_disp_valid
  ,input                           l2todr0_disp_retry
  ,output  I_l2todr_disp_type      l2todr0_disp

  ,input                           dr0tol2_dack_valid
  ,output                          dr0tol2_dack_retry
  ,input I_drtol2_dack_type        dr0tol2_dack

  ,input                           l2todr0_snoop_ack_valid
  ,output                          l2todr0_snoop_ack_retry
  ,input I_drsnoop_ack_type        l2todr0_snoop_ack

  ,input logic                     l2todr0_pfreq_valid
  ,output  logic                   l2todr0_pfreq_retry
  ,input I_l2todr_pfreq_type       l2todr0_pfreq

   // directory 1
  ,output                          l2todr1_req_valid
  ,input                           l2todr1_req_retry
  ,output  I_l2todr_req_type       l2todr1_req

  ,input                           dr1tol2_snack_valid
  ,output                          dr1tol2_snack_retry
  ,input I_drtol2_snack_type       dr1tol2_snack

  ,output                          l2todr1_disp_valid
  ,input                           l2todr1_disp_retry
  ,output  I_l2todr_disp_type      l2todr1_disp

  ,input                           dr1tol2_dack_valid
  ,output                          dr1tol2_dack_retry
  ,input I_drtol2_dack_type        dr1tol2_dack

  ,input                           l2todr1_snoop_ack_valid
  ,output                          l2todr1_snoop_ack_retry
  ,input I_drsnoop_ack_type        l2todr1_snoop_ack

  ,input logic                     l2todr1_pfreq_valid
  ,output  logic                   l2todr1_pfreq_retry
  ,input I_l2todr_pfreq_type       l2todr1_pfreq

  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
  );

  // Connecting everything in a simple crossbar. 

  // I am not sure how to determine what directory packets route to, so I'm routing everything from c0 to dir0 and c1 to dir1.
  // They need to be able to route to either ... 

  assign dr0tol2_snack_retry = c0_drtol2i_snack_retry | c0_drtol2it_snack_retry | c0_drtol2d_0_snack_retry | c0_drtol2dt_0_snack_retry;
  assign dr0tol2_dack_retry = c0_drtol2i_dack_retry | c0_drtol2it_dack_retry | c0_drtol2d_0_dack_retry | c0_drtol2dt_0_dack_retry;
  assign l2todr0_snoop_ack_retry = c0_drtol2i_snoop_ack_retry | c0_drtol2it_snoop_ack_retry | c0_drtol2d_0_snoop_ack_retry | c0_drtol2dt_0_snoop_ack_retry;
  assign l2todr0_pfreq_retry = c0_drtol2i_pfreq_retry | c0_drtol2it_pfreq_retry | c0_drtol2d_0_pfreq_retry | c0_drtol2dt_0_pfreq_retry;

  assign dr1tol2_snack_retry = c1_drtol2i_snack_retry | c1_drtol2it_snack_retry | c1_drtol2d_0_snack_retry | c1_drtol2dt_0_snack_retry;
  assign dr1tol2_dack_retry = c1_drtol2i_dack_retry | c1_drtol2it_dack_retry | c1_drtol2d_0_dack_retry | c1_drtol2dt_0_dack_retry;
  assign l2todr1_snoop_ack_retry = c1_drtol2i_snoop_ack_retry | c1_drtol2it_snoop_ack_retry | c1_drtol2d_0_snoop_ack_retry | c1_drtol2dt_0_snoop_ack_retry;
  assign l2todr1_pfreq_retry = c1_drtol2i_pfreq_retry | c1_drtol2it_pfreq_retry | c1_drtol2d_0_pfreq_retry | c1_drtol2dt_0_pfreq_retry;

  always_comb begin
  //***********************c0 core L2I***********************
    if (c0_l2itodr_req_valid) begin
      if (~c0_l2itodr_req.drid & ~!l2todr0_req_retry) begin // drid = 0
        l2todr0_req = c0_l2itodr_req;
      end else if (c0_l2itodr_req.drid  & ~!l2todr1_req_retry) begin  // drid  = 1
        l2todr1_req = c0_l2itodr_req;
      end else begin
      	c0_l2itodr_req_retry = 1;
      end
    end

    if (c0_l2itodr_disp_valid) begin
      if (~c0_l2itodr_disp.drid & ~!l2todr0_disp_retry) begin // drid = 0
        l2todr0_disp = c0_l2itodr_disp;
      end else if (c0_l2itodr_disp.drid  & ~!l2todr1_disp_retry) begin  // drid  = 1
        l2todr1_disp = c0_l2itodr_disp;
      end else begin
      	c0_l2itodr_disp_retry = 1;
      end
    end
    
    if (c0_drtol2i_dack_valid) begin
      if (~c0_drtol2i_dack.drid & ~!dr0tol2_dack_retry) begin // drid = 0
        dr0tol2_dack = c0_drtol2i_dack;
      end else if (c0_l2itodr_dack.drid  & ~!dr1tol2_dack_retry) begin  // drid  = 1
        dr1tol2_dack = c0_drtol2i_dack;
      end else begin
      	c0_drtol2i_dack_retry = 1;
      end
    end

    if (c1_l2itodr_pfreq_valid) begin
      if (~c0_l2itodr_dack.drid & ~!l2todr0_pfreq_retry) begin // drid = 0
        l2todr0_pfreq = c0_l2itodr_pfreq;
      end else if (c0_l2itodr_pfreq.drid  & ~!l2todr1_pfreq_retry) begin  // drid  = 1
        l2todr1_pfreq = c0_l2itodr_pfreq;
      end else begin
      	c0_l2itodr_pfreq_retry = 1;
      end
    end
    
//***********************c0 core L2I TLB***********************
    
	if (c0_l2ittodr_req_valid) begin
      if (~c0_l2ittodr_req.drid & ~!l2todr0_req_retry) begin // drid = 0
        l2todr0_req = c0_l2ittodr_req;
      end else if (c0_l2ittodr_req.drid  & ~!l2todr1_req_retry) begin  // drid  = 1
        l2todr1_req = c0_l2ittodr_req;
      end else begin
      	c0_l2ittodr_req_retry = 1;
      end
    end

    if (c0_l2ittodr_disp_valid) begin
      if (~c0_l2ittodr_disp.drid & ~!l2todr0_disp_retry) begin // drid = 0
        l2todr0_disp = c0_l2ittodr_disp;
      end else if (c0_l2ittodr_disp.drid  & ~!l2todr1_disp_retry) begin  // drid  = 1
        l2todr1_disp = c0_l2ittodr_disp;
      end else begin
      	c0_l2ittodr_disp_retry = 1;
      end
    end
    
    if (c0_drtol2it_dack_valid) begin
      if (~c0_drtol2it_dack.drid & ~!dr0tol2_dack_retry) begin // drid = 0
        dr0tol2_dack = c0_drtol2it_dack;
      end else if (c0_l2ittodr_dack.drid  & ~!dr1tol2_dack_retry) begin  // drid  = 1
        dr1tol2_dack = c0_drtol2it_dack;
      end else begin
      	c0_drtol2it_dack_retry = 1;
      end
    end

    //***********************c0 core L2D***********************

    if (c0_l2d_0todr_req_valid) begin
      if (c0_l2d_0todr_req.nid & 2'b0) begin
        l2todr0_req = c0_l2itodr_req;
      end else begin
        l2todr1_req = c0_l2itodr_req;
      end  
    end

    if (c0_l2d_0todr_disp_valid) begin
    end

    if (c0_drtol2d_0_dack_valid) begin
    end

    if (c0_l2d_0todr_pfreq_valid) begin
    end

    //***********************c0 core L2D TLB***********************

    if (c0_l2dt_0todr_req_valid) begin
      if (c0_l2dt_0todr_req.nid & 2'b0) begin
        l2todr0_req = c0_l2itodr_req;
      end else begin
        l2todr1_req = c0_l2itodr_req;
      end  
    end

    if (c0_l2dt_0todr_disp_valid) begin
    end

    if (c0_drtol2dt_0_dack_valid) begin
    end

    if (c0_l2dt_0todr_pfreq_valid) begin
    end

    //***********************c1 core L2I***********************

    if (c1_l2itodr_req_valid) begin
      if (~c1_l2itodr_req.drid & ~!l2todr0_req_retry) begin // drid = 0
        l2todr0_req = c1_l2itodr_req;
      end else if (c1_l2itodr_req.drid  & ~!l2todr1_req_retry) begin  // drid  = 1
        l2todr1_req = c1_l2itodr_req;
      end else begin
      	c1_l2itodr_req_retry = 1;
      end
    end

    if (c1_l2itodr_disp_valid) begin
      if (~c1_l2itodr_disp.drid & ~!l2todr0_disp_retry) begin // drid = 0
        l2todr0_disp = c1_l2itodr_disp;
      end else if (c1_l2itodr_disp.drid  & ~!l2todr1_disp_retry) begin  // drid  = 1
        l2todr1_disp = c1_l2itodr_disp;
      end else begin
      	c1_l2itodr_disp_retry = 1;
      end
    end
    
    if (c1_drtol2i_dack_valid) begin
      if (~c1_drtol2i_dack.drid & ~!dr0tol2_dack_retry) begin // drid = 0
        dr0tol2_dack = c1_drtol2i_dack;
      end else if (c1_l2itodr_dack.drid  & ~!dr1tol2_dack_retry) begin  // drid  = 1
        dr1tol2_dack = c1_drtol2i_dack;
      end else begin
      	c1_drtol2i_dack_retry = 1;
      end
    end

    if (c1_l2itodr_pfreq_valid) begin
      if (~c1_l2itodr_dack.drid & ~!l2todr0_pfreq_retry) begin // drid = 0
        l2todr0_pfreq = c1_l2itodr_pfreq;
      end else if (c1_l2itodr_pfreq.drid  & ~!l2todr1_pfreq_retry) begin  // drid  = 1
        l2todr1_pfreq = c1_l2itodr_pfreq;
      end else begin
      	c1_l2itodr_pfreq_retry = 1;
      end
    end

    //***********************c1 core L2I TLB***********************

    if (c1_l2ittodr_req_valid) begin
      if (c1_l2ittodr_req.nid & 2'b0) begin
        l2todr0_req = c0_l2itodr_req;
      end else begin
        l2todr1_req = c0_l2itodr_req;
      end  
    end

    if (c1_drtol2it_snack_retry) begin
    end

    if (c1_l2ittodr_snoop_ack_retry) begin
    end

    if (c1_l2ittodr_disp_valid) begin
    end

    if (c1_drtol2it_dack_valid) begin
    end

    //***********************c1 core L2D***********************

    if (c1_l2d_0todr_req_valid) begin
      if (c1_l2d_0todr_req.nid & 2'b0) begin
        l2todr0_req = c0_l2itodr_req;
      end else begin
        l2todr1_req = c0_l2itodr_req;
      end  
    end

    if (c1_l2d_0todr_disp_valid) begin
    end

    if (c1_drtol2d_0_dack_valid) begin
    end

    if (c1_l2d_0todr_pfreq_valid) begin
    end

    //***********************c1 core L2D TLB***********************

    if (c1_l2dt_0todr_req_valid) begin
      if (c1_l2dt_0todr_req.nid & 2'b0) begin
        l2todr0_req = c0_l2itodr_req;
      end else begin
        l2todr1_req = c0_l2itodr_req;
      end  
    end

    if (c1_l2dt_0todr_disp_valid) begin
    end

    if (c1_drtol2dt_0_dack_valid) begin
    end

    //***********************directory 0***********************

    if (l2todr0_req_valid) begin
      if (l2todr0_req.nid & 2'b0) begin
        l2todr0_req = c0_l2itodr_req;
      end else begin
        l2todr1_req = c0_l2itodr_req;
      end  
    end

    if (dr0tol2_snack_retry) begin
    end

    if (l2todr0_disp_valid) begin
    end

    if (dr0tol2_dack_retry) begin
    end

    if (l2todr0_snoop_ack_retry) begin
    end

    if (l2todr0_pfreq_retry) begin
    end

    //***********************directory 1***********************

    if (l2todr1_req_valid) begin
      if (l2todr1_req.nid & 2'b0) begin
        l2todr0_req = c0_l2itodr_req;
      end else begin
        l2todr1_req = c0_l2itodr_req;
      end  
    end

    if (dr1tol2_snack_retry) begin
    end

    if (l2todr1_disp_valid) begin
    end

    if (dr1tol2_dack_retry) begin
    end

    if (l2todr1_snoop_ack_retry) begin
    end

    if (l2todr1_pfreq_retry) begin
    end

  end

  // Connect L2s to directory using a ring or switch topology TBD

endmodule
