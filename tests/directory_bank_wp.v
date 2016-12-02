
`include "scmem.vh"

// Directory. Cache equivalent to 2MBytes/ 16 Way assoc
//
// Config size: 1M, 2M, 4M, 16M 16 way
//
// Assume a 64bytes line
//
// Conf Pending Requests. Two queues: one for request another for prefetch
//
// If prefetch queue is full, drop oldest 
//
// Parameter for the # of entry to remember: 4,8,16
// 
// For replacement use HawkEye or RRIP


module directory_bank_wp(
   input                           clk
  ,input                           reset

  // L2s interface
  ,input                           l2todr_pfreq_valid
  ,output                          l2todr_pfreq_retry
  ,input  SC_paddr_type            l2todr_pfreq_paddr
  ,input  SC_nodeid_type           l2todr_pfreq_nid 

  ,input                           l2todr_req_valid
  ,output                          l2todr_req_retry
  ,input  SC_nodeid_type           l2todr_req_nid 
  ,input  L2_reqid_type            l2todr_req_l2id
  ,input  SC_cmd_type              l2todr_req_cmd
  ,input  SC_paddr_type            l2todr_req_paddr

  ,output                          drtol2_snack_valid
  ,input                           drtol2_snack_retry
  ,output SC_nodeid_type           drtol2_snack_nid 
  ,output L2_reqid_type            drtol2_snack_l2id // !=0 ACK
  ,output DR_reqid_type            drtol2_snack_drid // !=0 snoop
  ,output DR_ndirs_type            drtol2_snack_directory_id 
  ,output SC_snack_type            drtol2_snack_snack
  ,output logic [`SC_LINEBYTES-1:0]              drtol2_snack_line_7 //yeah, I know the spacing is off...
  ,output logic [`SC_LINEBYTES-1:0]              drtol2_snack_line_6
  ,output logic [`SC_LINEBYTES-1:0]              drtol2_snack_line_5 
  ,output logic [`SC_LINEBYTES-1:0]              drtol2_snack_line_4 
  ,output logic [`SC_LINEBYTES-1:0]              drtol2_snack_line_3 
  ,output logic [`SC_LINEBYTES-1:0]              drtol2_snack_line_2 
  ,output logic [`SC_LINEBYTES-1:0]              drtol2_snack_line_1 
  ,output logic [`SC_LINEBYTES-1:0]              drtol2_snack_line_0 
  ,output DR_hpaddr_base_type      drtol2_snack_hpaddr_base
  ,output DR_hpaddr_hash_type      drtol2_snack_hpaddr_hash 
  ,output SC_paddr_type            drtol2_snack_paddr // Not used for ACKs

  ,input                           l2todr_disp_valid
  ,output                          l2todr_disp_retry
  ,input  SC_nodeid_type           l2todr_disp_nid 
  ,input  L2_reqid_type            l2todr_disp_l2id // != means L2 initiated disp (drid==0)
  ,input  DR_reqid_type            l2todr_disp_drid // !=0 snoop ack. (E.g: SMCD_WI resulting in a disp)
  ,input  SC_disp_mask_type        l2todr_disp_mask
  ,input  SC_dcmd_type             l2todr_disp_dcmd
  ,input  logic [`SC_LINEBYTES-1:0]       l2todr_disp_line_7
  ,input  logic [`SC_LINEBYTES-1:0]       l2todr_disp_line_6
  ,input  logic [`SC_LINEBYTES-1:0]       l2todr_disp_line_5
  ,input  logic [`SC_LINEBYTES-1:0]       l2todr_disp_line_4
  ,input  logic [`SC_LINEBYTES-1:0]       l2todr_disp_line_3
  ,input  logic [`SC_LINEBYTES-1:0]       l2todr_disp_line_2
  ,input  logic [`SC_LINEBYTES-1:0]       l2todr_disp_line_1
  ,input  logic [`SC_LINEBYTES-1:0]       l2todr_disp_line_0
  ,input  SC_paddr_type            l2todr_disp_paddr

  ,output                          drtol2_dack_valid
  ,input                           drtol2_dack_retry
  ,output SC_nodeid_type           drtol2_dack_nid
  ,output L2_reqid_type            drtol2_dack_l2id

  ,input                           l2todr_snoop_ack_valid 
  ,output                          l2todr_snoop_ack_retry
  ,input  DR_reqid_type            l2todr_snoop_ack_drid   
  ,input  DR_ndirs_type            l2todr_snoop_ack_directory_id 

  // Memory interface
  // If nobody has the data, send request to memory

  ,output                          drtomem_req_valid
  ,input                           drtomem_req_retry
  ,output DR_reqid_type            drtomem_req_drid
  ,output SC_cmd_type              drtomem_req_cmd
  ,output SC_paddr_type            drtomem_req_paddr

  ,input                           memtodr_ack_valid
  ,output                          memtodr_ack_retry
  ,input  DR_reqid_type            memtodr_ack_drid
  ,input  SC_nodeid_type           memtodr_ack_nid
  ,input  SC_paddr_type            memtodr_ack_paddr			
  ,input  SC_snack_type            memtodr_ack_ack // only ACK for mem
  ,input [`SC_LINEBYTES-1:0]              memtodr_ack_line_7 //yeah, I know the spacing is off...
  ,input [`SC_LINEBYTES-1:0]              memtodr_ack_line_6
  ,input [`SC_LINEBYTES-1:0]              memtodr_ack_line_5 
  ,input [`SC_LINEBYTES-1:0]              memtodr_ack_line_4 
  ,input [`SC_LINEBYTES-1:0]              memtodr_ack_line_3 
  ,input [`SC_LINEBYTES-1:0]              memtodr_ack_line_2 
  ,input [`SC_LINEBYTES-1:0]              memtodr_ack_line_1 
  ,input [`SC_LINEBYTES-1:0]              memtodr_ack_line_0 

  ,output                          drtomem_wb_valid
  ,input                           drtomem_wb_retry
  ,output logic [`SC_LINEBYTES-1:0]              drtomem_wb_line_7 //yeah, I know the spacing is off...
  ,output logic [`SC_LINEBYTES-1:0]              drtomem_wb_line_6
  ,output logic [`SC_LINEBYTES-1:0]              drtomem_wb_line_5 
  ,output logic [`SC_LINEBYTES-1:0]              drtomem_wb_line_4 
  ,output logic [`SC_LINEBYTES-1:0]              drtomem_wb_line_3 
  ,output logic [`SC_LINEBYTES-1:0]              drtomem_wb_line_2 
  ,output logic [`SC_LINEBYTES-1:0]              drtomem_wb_line_1 
  ,output logic [`SC_LINEBYTES-1:0]              drtomem_wb_line_0 
  ,output SC_disp_mask_type        drtomem_wb_mask
  ,output SC_paddr_type            drtomem_wb_paddr

  ,output logic                    drtomem_pfreq_valid
  ,input  logic                    drtomem_pfreq_retry
  ,output SC_nodeid_type           drtomem_pfreq_nid
  ,output SC_paddr_type            drtomem_pfreq_paddr

  );
  
  //There seems to be a little glitch with the testbench. When it samples the signals, it does so after a clock edge.
  //So many of the tests where we think we are sampling the positive edge of the clock, we are actually looking at the values
  //slightly after. 
  //The situation: In perfect simulator world, this does not cause a problem. Many of the signals include a valid and retry
  //and when the testbench samples them slightly after the posedge of the clock, that value is usually maintained until the next
  //posedge so their is not problem.
  //The problem: a problem occurs when the module tries to use logic inputs from the testbench. For some reason, the testbench inputs
  //get registered on negedges (even though it looks like they appear on posedges). This causes logic that would appear slightly after
  //the posedge to be shifted to the negedge if using an input from the testbench. However, this now causes an error because the 
  //testbench samples after the posedge. The valid/retry signals may change after the negedge which means the testbench misses these
  //inputs because it only sampled after the posedge.
  //Solution: Other than fixing the testbench which will take a long time because I mostly copy and pasted my testbench code from
  //other files, I will try to fix this by using extra fflops. By using a fflop between the inputs and outputs to the testbench, it
  //will hopefully synchronize the logic back to the posedge and remove the negedge logic. 
  
  logic l2todr_req_ff_valid;
  logic l2todr_req_ff_retry;
  I_l2todr_req_type l2todr_req_wpff;
  I_l2todr_req_type l2todr_req_wpff_next;
  
  always_comb begin
    l2todr_req_wpff_next.nid = l2todr_req_nid;
    l2todr_req_wpff_next.l2id = l2todr_req_l2id;
    l2todr_req_wpff_next.cmd = l2todr_req_cmd;
    l2todr_req_wpff_next.paddr = l2todr_req_paddr;
  end

  fflop #(.Size($bits(I_l2todr_req_type))) l2todr_req_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (l2todr_req_wpff_next),
    .dinValid (l2todr_req_valid),
    .dinRetry (l2todr_req_retry),

    .q        (l2todr_req_wpff),
    .qValid   (l2todr_req_ff_valid),
    .qRetry   (l2todr_req_ff_retry)
  );
  
  logic memtodr_ack_ff_valid;
  logic memtodr_ack_ff_retry;
  I_memtodr_ack_type memtodr_ack_wpff;
  

  fflop #(.Size($bits(I_memtodr_ack_type))) memtodr_ack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      ({  memtodr_ack_drid
		               ,memtodr_ack_nid
		               ,memtodr_ack_paddr
                   ,memtodr_ack_ack
                   ,memtodr_ack_line_7
                   ,memtodr_ack_line_6
                   ,memtodr_ack_line_5
                   ,memtodr_ack_line_4
                   ,memtodr_ack_line_3
                   ,memtodr_ack_line_2
                   ,memtodr_ack_line_1
                   ,memtodr_ack_line_0}),
    .dinValid (memtodr_ack_valid),
    .dinRetry (memtodr_ack_retry),

    .q        (memtodr_ack_wpff),
    .qValid   (memtodr_ack_ff_valid),
    .qRetry   (memtodr_ack_ff_retry)
  );
  
  logic l2todr_disp_ff_valid;
  logic l2todr_disp_ff_retry;
  I_l2todr_disp_type l2todr_disp_wpff;
  

  fflop #(.Size($bits(I_l2todr_disp_type))) l2todr_disp_ff (
    .clk      (clk),
    .reset    (reset),

    .din      ({  l2todr_disp_nid
                   ,l2todr_disp_l2id
                   ,l2todr_disp_drid
                   ,l2todr_disp_mask
                   ,l2todr_disp_dcmd
                   ,l2todr_disp_line_7
                   ,l2todr_disp_line_6
                   ,l2todr_disp_line_5
                   ,l2todr_disp_line_4
                   ,l2todr_disp_line_3
                   ,l2todr_disp_line_2
                   ,l2todr_disp_line_1
                   ,l2todr_disp_line_0
                   ,l2todr_disp_paddr}),
    .dinValid (l2todr_disp_valid),
    .dinRetry (l2todr_disp_retry),

    .q        (l2todr_disp_wpff),
    .qValid   (l2todr_disp_ff_valid),
    .qRetry   (l2todr_disp_ff_retry)
  );
  
  logic l2todr_snoop_ack_ff_valid;
  logic l2todr_snoop_ack_ff_retry;
  I_drsnoop_ack_type l2todr_snoop_ack_wpff;
  
  fflop #(.Size($bits(I_drsnoop_ack_type))) l2todr_snoop_ack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (       {l2todr_snoop_ack_drid
                      ,l2todr_snoop_ack_directory_id}),
    .dinValid (l2todr_snoop_ack_valid),
    .dinRetry (l2todr_snoop_ack_retry),

    .q        (l2todr_snoop_ack_wpff),
    .qValid   (l2todr_snoop_ack_ff_valid),
    .qRetry   (l2todr_snoop_ack_ff_retry)
  );
  
  logic drtomem_wb_ff_valid;
  logic drtomem_wb_ff_retry;
  I_drtomem_wb_type drtomem_wb_wpff;
  

  fflop #(.Size($bits(I_drtomem_wb_type))) drtomem_wb_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtomem_wb_wpff),
    .dinValid (drtomem_wb_ff_valid),
    .dinRetry (drtomem_wb_ff_retry),

    .q        ({   drtomem_wb_line_7
                   ,drtomem_wb_line_6
                   ,drtomem_wb_line_5
                   ,drtomem_wb_line_4
                   ,drtomem_wb_line_3
                   ,drtomem_wb_line_2
                   ,drtomem_wb_line_1
                   ,drtomem_wb_line_0
		               ,drtomem_wb_mask
                   ,drtomem_wb_paddr}),
    .qValid   (drtomem_wb_valid),
    .qRetry   (drtomem_wb_retry)
  );
  
  logic drtol2_dack_ff_valid;
  logic drtol2_dack_ff_retry;
  I_drtol2_dack_type drtol2_dack_wpff;
  

  fflop #(.Size($bits(I_drtol2_dack_type))) drtol2_dack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtol2_dack_wpff),
    .dinValid (drtol2_dack_ff_valid),
    .dinRetry (drtol2_dack_ff_retry),

    .q        ({    drtol2_dack_nid
                   ,drtol2_dack_l2id}),
    .qValid   (drtol2_dack_valid),
    .qRetry   (drtol2_dack_retry)
  );
  
  logic drtomem_req_ff_valid;
  logic drtomem_req_ff_retry;
  I_drtomem_req_type drtomem_req_wpff;
  

  fflop #(.Size($bits(I_drtomem_req_type))) drtomem_req_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtomem_req_wpff),
    .dinValid (drtomem_req_ff_valid),
    .dinRetry (drtomem_req_ff_retry),

    .q       ({drtomem_req_drid
              ,drtomem_req_cmd
              ,drtomem_req_paddr}),
    .qValid   (drtomem_req_valid),
    .qRetry   (drtomem_req_retry)
  );
  
  
  logic drtol2_snack_ff_valid;
  logic drtol2_snack_ff_retry;
  I_drtol2_snack_type drtol2_snack_wpff;
  

  fflop #(.Size($bits(I_drtol2_snack_type))) drtol2_snack_ff (
    .clk      (clk),
    .reset    (reset),

    .din      (drtol2_snack_wpff),
    .dinValid (drtol2_snack_ff_valid),
    .dinRetry (drtol2_snack_ff_retry),

    .q       ({     drtol2_snack_nid
                   ,drtol2_snack_l2id
                   ,drtol2_snack_drid
                   ,drtol2_snack_directory_id
                   ,drtol2_snack_snack
                   ,drtol2_snack_line_7
                   ,drtol2_snack_line_6
                   ,drtol2_snack_line_5
                   ,drtol2_snack_line_4
                   ,drtol2_snack_line_3
                   ,drtol2_snack_line_2
                   ,drtol2_snack_line_1
                   ,drtol2_snack_line_0
                   ,drtol2_snack_hpaddr_base
                   ,drtol2_snack_hpaddr_hash
                   ,drtol2_snack_paddr}),
    .qValid   (drtol2_snack_valid),
    .qRetry   (drtol2_snack_retry)
  );
  
  directory_bank 
  #(.Directory_Id(0))
  dr(
    .clk(clk)
   ,.reset(reset)

  // L2s interface
   ,.l2todr_pfreq_valid(l2todr_pfreq_valid)
   ,.l2todr_pfreq_retry(l2todr_pfreq_retry)
   ,.l2todr_pfreq({     l2todr_pfreq_nid
                       ,l2todr_pfreq_paddr})       // NOTE: pfreq does not have ack if dropped
     
   ,.l2todr_req_valid(l2todr_req_ff_valid)
   ,.l2todr_req_retry(l2todr_req_ff_retry)
   ,.l2todr_req(l2todr_req_wpff)

   ,.drtol2_snack_valid(drtol2_snack_ff_valid)
   ,.drtol2_snack_retry(drtol2_snack_ff_retry)
   ,.drtol2_snack(drtol2_snack_wpff)

   ,.l2todr_disp_valid(l2todr_disp_ff_valid)
   ,.l2todr_disp_retry(l2todr_disp_ff_retry)
   ,.l2todr_disp(l2todr_disp_wpff)

   ,.drtol2_dack_valid(drtol2_dack_ff_valid)
   ,.drtol2_dack_retry(drtol2_dack_ff_retry)
   ,.drtol2_dack(drtol2_dack_wpff)

   ,.l2todr_snoop_ack_valid(l2todr_snoop_ack_ff_valid)
   ,.l2todr_snoop_ack_retry(l2todr_snoop_ack_ff_retry)
   ,.l2todr_snoop_ack(l2todr_snoop_ack_wpff)

  // Memory interface
  // If nobody has the data, send request to memory

   ,.drtomem_req_valid(drtomem_req_ff_valid)
   ,.drtomem_req_retry(drtomem_req_ff_retry)
   ,.drtomem_req(drtomem_req_wpff)

   ,.memtodr_ack_valid(memtodr_ack_ff_valid)
   ,.memtodr_ack_retry(memtodr_ack_ff_retry)
   ,.memtodr_ack(memtodr_ack_wpff)
   // ,.memtodr_ack_valid(memtodr_ack_valid)
   // ,.memtodr_ack_retry(memtodr_ack_retry)
   // ,.memtodr_ack({  memtodr_ack_drid
		               // ,memtodr_ack_nid
		               // ,memtodr_ack_paddr
                   // ,memtodr_ack_ack
                   // ,memtodr_ack_line_7
                   // ,memtodr_ack_line_6
                   // ,memtodr_ack_line_5
                   // ,memtodr_ack_line_4
                   // ,memtodr_ack_line_3
                   // ,memtodr_ack_line_2
                   // ,memtodr_ack_line_1
                   // ,memtodr_ack_line_0})

   ,.drtomem_wb_valid(drtomem_wb_ff_valid)
   ,.drtomem_wb_retry(drtomem_wb_ff_retry)
   ,.drtomem_wb(drtomem_wb_wpff) // Plain WB, no disp ack needed

   ,.drtomem_pfreq_valid(drtomem_pfreq_valid)
   ,.drtomem_pfreq_retry(drtomem_pfreq_retry)
   ,.drtomem_pfreq({ drtomem_pfreq_nid
		                ,drtomem_pfreq_paddr})
  );

endmodule

