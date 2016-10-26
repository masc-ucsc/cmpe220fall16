module l2tlb_wp(
  /* verilator lint_off UNUSED */
   input                           clk
  ,input                           reset

  // L2TLB listens the same L1 request (but no ack). Response sent to L2
  ,input                            l1tol2tlb_req_valid
  ,output                           l1tol2tlb_req_retry
  ,input  I_l1tol2tlb_req_type      l1tol2tlb_req
  ,input  L1_reqid_type			    l1tol2tlb_req_l1id;
  ,input  logic                     l1tol2tlb_req_prefetch;
  ,input  SC_poffset_type           l1tol2tlb_req_poffset;
  ,input  TLB_hpaddr_type           l1tol2tlb_req_hpaddr;

  ,output                           l2tlbtol2_fwd_valid
  ,input                            l2tlbtol2_fwd_retry
  ,output I_l2tlbtol2_fwd_type      l2tlbtol2_fwd
  ,output L1_reqid_type     	    l2tlbtol2_fwd_l1id;
  ,output logic                     l2tlbtol2_fwd_prefetch;
  ,output SC_fault_type             l2tlbtol2_fwd_fault;
  ,output TLB_hpaddr_type           l2tlbtol2_fwd_hpaddr;
  ,output SC_paddr_type             l2tlbtol2_fwd_paddr;

  // l1TLB and L2TLB interface
  ,output                           l2tlbtol1tlb_snoop_valid
  ,input                            l2tlbtol1tlb_snoop_retry
  ,output I_l2tlbtol1tlb_snoop_type l2tlbtol1tlb_snoop
  ,output TLB_reqid_type    		l2tlbtol1tlb_snoop_rid;
  ,output TLB_hpaddr_type   		l2tlbtol1tlb_snoop_hpaddr;

  ,output                           l2tlbtol1tlb_ack_valid
  ,input                            l2tlbtol1tlb_ack_retry
  ,output I_l2tlbtol1tlb_ack_type   l2tlbtol1tlb_ack
  ,output TLB_reqid_type    		l2tlbtol1tlb_ack_rid;
  ,output TLB_hpaddr_type  			l2tlbtol1tlb_ack_hpaddr; // hash paddr 
  ,output SC_ppaddr_type   			l2tlbtol1tlb_ack_ppaddr; // predicted PADDR
  ,output SC_dctlbe_type    		l2tlbtol1tlb_ack_dctlbe; // ack

  ,input                            l1tlbtol2tlb_req_valid
  ,output                           l1tlbtol2tlb_req_retry
  ,input  I_l1tlbtol2tlb_req_type   l1tlbtol2tlb_req
  ,input  TLB_reqid_type		    l1tlbtol2tlb_req_rid;
  ,input  logic             		l1tlbtol2tlb_req_disp_req; // True of disp from dcTLB (A/D bits)
  ,input  logic            			l1tlbtol2tlb_req_disp_A;
  ,input  logic             		l1tlbtol2tlb_req_disp_D;
  ,input  TLB_hpaddr_type   		l1tlbtol2tlb_req_disp_hpaddr; // hash paddr 
  ,input  SC_laddr_type    			l1tlbtol2tlb_req_laddr; // Not during disp, just req
  ,input  SC_sptbr_type   		 	l1tlbtol2tlb_req_sptbr; // Not during disp, just req

  ,input                            l1tlbtol2tlb_sack_valid
  ,output                           l1tlbtol2tlb_sack_retry
  ,input  I_l1tlbtol2tlb_sack_type  l1tlbtol2tlb_sack
  ,input  TLB_reqid_type   			l1tlbtol2tlb_sack_rid;
  
  //---------------------------
  // Directory interface (l2 has to arbitrate between L2 and L2TLB
  // messages based on nodeid. Even nodeid is L2, odd is L2TLB)
  ,output                           l2todr_req_valid
  ,input                            l2todr_req_retry
  ,output I_l2todr_req_type         l2todr_req
  ,output SC_nodeid_type    		l2todr_req_nid; 
  ,output L2_reqid_type     		l2todr_req_l2id;
  ,output SC_cmd_type       		l2todr_req_cmd;
  ,output SC_paddr_type     		l2todr_req_paddr;

  ,input                            drtol2_snack_valid
  ,output                           drtol2_snack_retry
  ,input  I_drtol2_snack_type       drtol2_snack
  ,input  SC_nodeid_type 		    drtol2_snack_nid; 
  ,input  L2_reqid_type     		drtol2_snack_l2id; // !=0 ACK
  ,input  DR_reqid_type     		drtol2_snack_drid; // !=0 snoop
  ,input  SC_snack_type     		drtol2_snack_snack;
  ,input  SC_line_type      		drtol2_snack_line;
  ,input  SC_paddr_type     		drtol2_snack_paddr; // Not used for ACKs

  ,output                           l2todr_snoop_ack_valid
  ,input                            l2todr_snoop_ack_retry
  ,output I_l2snoop_ack_type        l2todr_snoop_ack
  ,output L2_reqid_type     		l2todr_snoop_ack_l2id;

  ,output                           l2todr_disp_valid
  ,input                            l2todr_disp_retry
  ,output I_l2todr_disp_type        l2todr_disp
  ,output SC_nodeid_type   			l2todr_disp_nid; 
  ,output L2_reqid_type   			l2todr_disp_l2id; // != means L2 initiated disp (drid==0)
  ,output DR_reqid_type    			l2todr_disp_drid; // !=0 snoop ack. (E.g: SMCD_WI resulting in a disp)
  ,output SC_disp_mask_type 		l2todr_disp_mask;
  ,output SC_dcmd_type      		l2todr_disp_dcmd;
  ,output SC_line_type      		l2todr_disp_line;
  ,output SC_paddr_type     		l2todr_disp_paddr;

  ,input                            drtol2_dack_valid
  ,output                           drtol2_dack_retry
  ,input  I_drtol2_dack_type        drtol2_dack
  ,input  SC_nodeid_type 		    drtol2_dack_nid; 
  ,input  L2_reqid_type     		drtol2_dack_l2id;
  /* verilator lint_on UNUSED */
);

endmodule