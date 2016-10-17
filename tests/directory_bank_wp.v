//lines to compile, removed 'r' from verilato because the program will think its a directive
//verilato --assert --debug-check -I./rtl --Wall --cc --trace --top-module directory_bank_wp ./tests/directory_bank_wp.v ./rtl/directory_bank.v ./rtl/fflop.v --exe tests/directory_bank_wp_tb.cpp -CFLAGS -DTRACE=1	
// make -C obj_dir/ -f Vdirectory_bank_wp.mk Vdirectory_bank_wp

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

//this directives are set just to let me compile until I make the connections

module directory_bank_wp(
   input                           clk
  ,input                           reset

  // L2s interface
  ,input                           l2todr_pfreq_valid
  ,output                          l2todr_pfreq_retry
  ,input  SC_paddr_type            l2todr_pfreq_paddr

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
  ,output SC_snack_type            drtol2_snack_snack
  ,output SC_line_type             drtol2_snack_line //line needs to be divided into smaller chunks
  ,output SC_paddr_type            drtol2_snack_paddr // Not used for ACKs

  ,input                           l2todr_disp_valid
  ,output                          l2todr_disp_retry
  ,input  SC_nodeid_type           l2todr_disp_nid 
  ,input  L2_reqid_type            l2todr_disp_l2id // != means L2 initiated disp (drid==0)
  ,input  DR_reqid_type            l2todr_disp_drid // !=0 snoop ack. (E.g: SMCD_WI resulting in a disp)
  ,input  SC_disp_mask_type        l2todr_disp_mask
  ,input  SC_dcmd_type             l2todr_disp_dcmd
  ,input  SC_line_type             l2todr_disp_line
  ,input  SC_paddr_type            l2todr_disp_paddr

  ,output                          drtol2_dack_valid
  ,input                           drtol2_dack_retry
  ,output SC_nodeid_type           drtol2_dack_nid
  ,output L2_reqid_type            drtol2_dack_l2id

  ,output                          l2todr_snoop_ack_valid //should these set of signals 
  ,input                           l2todr_snoop_ack_retry
  ,output DR_reqid_type            l2todr_snoop_ack_drid  //should this be an input? This guess is based on the l2todr naming and they appear to be the ack from a directory snoops    

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
  ,input  SC_snack_type            memtodr_ack_ack // only ACK for mem
  ,input  SC_line_type             memtodr_ack_line

  ,output                          drtomem_wb_valid
  ,input                           drtomem_wb_retry
  ,output SC_line_type             drtomem_wb_line
  ,output SC_paddr_type            drtomem_wb_paddr

  ,output logic                    drtomem_pfreq_valid
  ,input  logic                    drtomem_pfreq_retry
  ,output SC_paddr_type            drtomem_pfreq_paddr

  );

  directory_bank 
  dr(
    .clk(clk)
   ,.reset(reset)

  // L2s interface
   ,.l2todr_pfreq_valid(l2todr_pfreq_valid)
   ,.l2todr_pfreq_retry(l2todr_pfreq_retry)
   ,.l2todr_pfreq(l2todr_pfreq_paddr)       // NOTE: pfreq does not have ack if dropped

   ,.l2todr_req_valid(l2todr_req_valid)
   ,.l2todr_req_retry(l2todr_req_retry)
   ,.l2todr_req({   l2todr_req_nid
                   ,l2todr_req_l2id
                   ,l2todr_req_cmd
                   ,l2todr_req_paddr})

   ,.drtol2_snack_valid(drtol2_snack_valid)
   ,.drtol2_snack_retry(drtol2_snack_retry)
   ,.drtol2_snack({ drtol2_snack_nid
                   ,drtol2_snack_l2id
                   ,drtol2_snack_drid
                   ,drtol2_snack_snack
                   ,drtol2_snack_line
                   ,drtol2_snack_paddr})

   ,.l2todr_disp_valid(l2todr_disp_valid)
   ,.l2todr_disp_retry(l2todr_disp_retry)
   ,.l2todr_disp({  l2todr_disp_nid
                   ,l2todr_disp_l2id
                   ,l2todr_disp_drid
                   ,l2todr_disp_mask
                   ,l2todr_disp_dcmd
                   ,l2todr_disp_line
                   ,l2todr_disp_paddr})

   ,.drtol2_dack_valid(drtol2_dack_valid)
   ,.drtol2_dack_retry(drtol2_dack_retry)
   ,.drtol2_dack({  drtol2_dack_nid
                   ,drtol2_dack_l2id})

   ,.l2todr_snoop_ack_valid(l2todr_snoop_ack_valid)
   ,.l2todr_snoop_ack_retry(l2todr_snoop_ack_retry)
   ,.l2todr_snoop_ack(l2todr_snoop_ack_drid)

  // Memory interface
  // If nobody has the data, send request to memory

   ,.drtomem_req_valid(drtomem_req_valid)
   ,.drtomem_req_retry(drtomem_req_retry)
   ,.drtomem_req({  drtomem_req_drid
                   ,drtomem_req_cmd
                   ,drtomem_req_paddr})

   ,.memtodr_ack_valid(memtodr_ack_valid)
   ,.memtodr_ack_retry(memtodr_ack_retry)
   ,.memtodr_ack({  memtodr_ack_drid
                   ,memtodr_ack_ack
                   ,memtodr_ack_line})

   ,.drtomem_wb_valid(drtomem_wb_valid)
   ,.drtomem_wb_retry(drtomem_wb_retry)
   ,.drtomem_wb({   drtomem_wb_line
                   ,drtomem_wb_paddr}) // Plain WB, no disp ack needed

   ,.drtomem_pfreq_valid(drtomem_pfreq_valid)
   ,.drtomem_pfreq_retry(drtomem_pfreq_retry)
   ,.drtomem_pfreq(drtomem_pfreq_paddr)
  );

   
endmodule


