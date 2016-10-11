
// FIXME:
//
// Any l2 cache pipe can go to any directory (and viceversa). The reason is to
// allow a per bank SMT option (dc_pipe and l2_pipe) and to handle the TLB
// misses that can go out of bank.
//
// Effectively, a 4 pipe dual core can switch to a 8 independent l2 coherent
// cores. No need to have a switch command as the DCs and L2s are coherent.

module net_2core2dr_wp(
  /* verilator lint_off UNUSED */
  /* verilator lint_off UNDRIVEN */
	input	logic				clk
	,input	logic				reset

  // c0 core L2D and L2I
	,input	logic				c0_l2itodr_req_valid
	,output	logic				c0_l2itodr_req_retry
	//  ,input  I_l2todr_req_type        c0_l2itodr_req
	,input	SC_nodeid_type		c0_l2itodr_req_nid
	,input	L2_reqid_type		c0_l2itodr_req_l2id
	,input	SC_cmd_type			c0_l2itodr_req_cmd
	,input	SC_paddr_type		c0_l2itodr_req_paddr

	,output	logic				c0_drtol2i_snack_valid
	,input	logic				c0_drtol2i_snack_retry
	//  ,output I_drtol2_snack_type      c0_drtol2i_snack
	,output	SC_nodeid_type		c0_drtol2i_snack_nid
	,output	L2_reqid_type		c0_drtol2i_snack_l2id
	,output	DR_reqid_type		c0_drtol2i_snack_drid
	,output	SC_snack_type		c0_drtol2i_snack_snack
	,output	SC_line_type		c0_drtol2i_snack_line
	,output	SC_paddr_type		c0_drtol2i_snack_paddr

	,output	logic				c0_drtol2i_snoop_ack_valid
	,input	logic				c0_drtol2i_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c0_drtol2i_snoop_ack
	,output	L2_reqid_type		c0_drtol2i_snoop_ack_l2id

	,input	logic				c0_l2itodr_disp_valid
	,output	logic				c0_l2itodr_disp_retry
	//  ,input  I_l2todr_disp_type       c0_l2itodr_disp
	,input	SC_nodeid_type		c0_l2itodr_disp_nid
	,input	L2_reqid_type		c0_l2itodr_disp_l2id
	,input	DR_reqid_type		c0_l2itodr_disp_drid
	,input	SC_disp_mask_type	c0_l2itodr_disp_mask
	,input	SC_dcmd_type		c0_l2itodr_disp_dcmd
	,input	SC_line_type		c0_l2itodr_disp_line
	,input	SC_paddr_type		c0_l2itodr_disp_paddr

	,input	logic				c0_drtol2i_dack_valid
	,output	logic				c0_drtol2i_dack_retry
	//  ,input  I_drtol2_dack_type       c0_drtol2i_dack
	,input	SC_nodeid_type		c0_drtol2i_dack_nid
	,input	L2_reqid_type		c0_drtol2i_dack_l2id

  // L2D_0
	,input	logic				c0_l2d_0todr_req_valid
	,output	logic				c0_l2d_0todr_req_retry
	//  ,input  I_l2todr_req_type        c0_l2d_0todr_req
	,input	SC_nodeid_type		c0_l2d_0todr_req_nid
	,input	L2_reqid_type		c0_l2d_0todr_req_l2id
	,input	SC_cmd_type			c0_l2d_0todr_req_cmd
	,input	SC_paddr_type		c0_l2d_0todr_req_paddr

	,output	logic				c0_drtol2d_0_snack_valid
	,input	logic				c0_drtol2d_0_snack_retry
	//  ,output I_drtol2_snack_type      c0_drtol2d_0_snack
	,output	SC_nodeid_type		c0_drtol2d_0_snack_nid
	,output	L2_reqid_type		c0_drtol2d_0_snack_l2id
	,output	DR_reqid_type		c0_drtol2d_0_snack_drid
	,output	SC_snack_type		c0_drtol2d_0_snack_snack
	,output	SC_line_type		c0_drtol2d_0_snack_line
	,output	SC_paddr_type		c0_drtol2d_0_snack_paddr

	,output	logic				c0_drtol2d_0_snoop_ack_valid
	,input	logic				c0_drtol2d_0_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c0_drtol2d_0_snoop_ack
	,output	L2_reqid_type		c0_drtol2d_0_snoop_ack_l2id

	,input	logic				c0_l2d_0todr_disp_valid
	,output	logic				c0_l2d_0todr_disp_retry
	//  ,input  I_l2todr_disp_type       c0_l2d_0todr_disp
	,input	SC_nodeid_type		c0_l2d_0todr_disp_nid
	,input	L2_reqid_type		c0_l2d_0todr_disp_l2id
	,input	DR_reqid_type		c0_l2d_0todr_disp_drid
	,input	SC_disp_mask_type	c0_l2d_0todr_disp_mask
	,input	SC_dcmd_type		c0_l2d_0todr_disp_dcmd
	,input	SC_line_type		c0_l2d_0todr_disp_line
	,input	SC_paddr_type		c0_l2d_0todr_disp_paddr

	,input	logic				c0_drtol2d_0_dack_valid
	,output	logic				c0_drtol2d_0_dack_retry
	//  ,input  I_drtol2_dack_type       c0_drtol2d_0_dack
	,input	SC_nodeid_type		c0_drtol2d_0_dack_nid
	,input	L2_reqid_type		c0_drtol2d_0_dack_l2id

  // L2D_1
	,input	logic				c0_l2d_1todr_req_valid
	,output	logic				c0_l2d_1todr_req_retry
	//  ,input  I_l2todr_req_type        c0_l2d_1todr_req
	,input	SC_nodeid_type		c0_l2d_1todr_req_nid
	,input	L2_reqid_type		c0_l2d_1todr_req_l2id
	,input	SC_cmd_type			c0_l2d_1todr_req_cmd
	,input	SC_paddr_type		c0_l2d_1todr_req_paddr

	,output	logic				c0_drtol2d_1_snack_valid
	,input	logic				c0_drtol2d_1_snack_retry
	//  ,output I_drtol2_snack_type      c0_drtol2d_1_snack
	,output	SC_nodeid_type		c0_drtol2d_1_snack_nid
	,output	L2_reqid_type		c0_drtol2d_1_snack_l2id
	,output	DR_reqid_type		c0_drtol2d_1_snack_drid
	,output	SC_snack_type		c0_drtol2d_1_snack_snack
	,output	SC_line_type		c0_drtol2d_1_snack_line
	,output	SC_paddr_type		c0_drtol2d_1_snack_paddr

	,output	logic				c0_drtol2d_1_snoop_ack_valid
	,input	logic				c0_drtol2d_1_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c0_drtol2d_1_snoop_ack
	,output	L2_reqid_type		c0_drtol2d_1_snoop_ack_l2id

	,input	logic				c0_l2d_1todr_disp_valid
	,output	logic				c0_l2d_1todr_disp_retry
	//  ,input  I_l2todr_disp_type       c0_l2d_1todr_disp
	,input	SC_nodeid_type		c0_l2d_1todr_disp_nid
	,input	L2_reqid_type		c0_l2d_1todr_disp_l2id
	,input	DR_reqid_type		c0_l2d_1todr_disp_drid
	,input	SC_disp_mask_type	c0_l2d_1todr_disp_mask
	,input	SC_dcmd_type		c0_l2d_1todr_disp_dcmd
	,input	SC_line_type		c0_l2d_1todr_disp_line
	,input	SC_paddr_type		c0_l2d_1todr_disp_paddr

	,input	logic				c0_drtol2d_1_dack_valid
	,output	logic				c0_drtol2d_1_dack_retry
	//  ,input  I_drtol2_dack_type       c0_drtol2d_1_dack
	,input	SC_nodeid_type		c0_drtol2d_1_dack_nid
	,input	L2_reqid_type		c0_drtol2d_1_dack_l2id

`ifdef SC_4PIPE
  // l2d_2
	,input	logic				c0_l2d_2todr_req_valid
	,output	logic				c0_l2d_2todr_req_retry
	//  ,input  I_l2todr_req_type        c0_l2d_2todr_req
	,input	SC_nodeid_type		c0_l2d_2todr_req_nid
	,input	L2_reqid_type		c0_l2d_2todr_req_l2id
	,input	SC_cmd_type			c0_l2d_2todr_req_cmd
	,input	SC_paddr_type		c0_l2d_2todr_req_paddr

	,output	logic				c0_drtol2d_2_snack_valid
	,input	logic				c0_drtol2d_2_snack_retry
	//  ,output I_drtol2_snack_type      c0_drtol2d_2_snack
	,output	SC_nodeid_type		c0_drtol2d_2_snack_nid
	,output	L2_reqid_type		c0_drtol2d_2_snack_l2id
	,output	DR_reqid_type		c0_drtol2d_2_snack_drid
	,output	SC_snack_type		c0_drtol2d_2_snack_snack
	,output	SC_line_type		c0_drtol2d_2_snack_line
	,output	SC_paddr_type		c0_drtol2d_2_snack_paddr

	,output	logic				c0_drtol2d_2_snoop_ack_valid
	,input	logic				c0_drtol2d_2_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c0_drtol2d_2_snoop_ack
	,output	L2_reqid_type		c0_drtol2d_2_snoop_ack_l2id

	,input	logic				c0_l2d_2todr_disp_valid
	,output	logic				c0_l2d_2todr_disp_retry
	//  ,input  I_l2todr_disp_type       c0_l2d_2todr_disp
	,input	SC_nodeid_type		c0_l2d_2todr_disp_nid
	,input	L2_reqid_type		c0_l2d_2todr_disp_l2id
	,input	DR_reqid_type		c0_l2d_2todr_disp_drid
	,input	SC_disp_mask_type	c0_l2d_2todr_disp_mask
	,input	SC_dcmd_type		c0_l2d_2todr_disp_dcmd
	,input	SC_line_type		c0_l2d_2todr_disp_line
	,input	SC_paddr_type		c0_l2d_2todr_disp_paddr

	,input	logic				c0_drtol2d_2_dack_valid
	,output	logic				c0_drtol2d_2_dack_retry
	//  ,input  I_drtol2_dack_type       c0_drtol2d_2_dack
	,input	SC_nodeid_type		c0_drtol2d_2_dack_nid
	,input	L2_reqid_type		c0_drtol2d_2_dack_l2id

  // l2d_3
	,input	logic				c0_l2d_3todr_req_valid
	,output	logic				c0_l2d_3todr_req_retry
	//  ,input  I_l2todr_req_type        c0_l2d_3todr_req
	,input	SC_nodeid_type		c0_l2d_3todr_req_nid
	,input	L2_reqid_type		c0_l2d_3todr_req_l2id
	,input	SC_cmd_type			c0_l2d_3todr_req_cmd
	,input	SC_paddr_type		c0_l2d_3todr_req_paddr

	,output	logic				c0_drtol2d_3_snack_valid
	,input	logic				c0_drtol2d_3_snack_retry
	//  ,output I_drtol2_snack_type      c0_drtol2d_3_snack
	,output	SC_nodeid_type		c0_drtol2d_3_snack_nid
	,output	L2_reqid_type		c0_drtol2d_3_snack_l2id
	,output	DR_reqid_type		c0_drtol2d_3_snack_drid
	,output	SC_snack_type		c0_drtol2d_3_snack_snack
	,output	SC_line_type		c0_drtol2d_3_snack_line
	,output	SC_paddr_type		c0_drtol2d_3_snack_paddr

	,output	logic				c0_drtol2d_3_snoop_ack_valid
	,input	logic				c0_drtol2d_3_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c0_drtol2d_3_snoop_ack
	,output	L2_reqid_type		c0_drtol2d_3_snoop_ack_l2id

	,input	logic				c0_l2d_3todr_disp_valid
	,output	logic				c0_l2d_3todr_disp_retry
	//  ,input  I_l2todr_disp_type       c0_l2d_3todr_disp
	,input	SC_nodeid_type		c0_l2d_3todr_disp_nid
	,input	L2_reqid_type		c0_l2d_3todr_disp_l2id
	,input	DR_reqid_type		c0_l2d_3todr_disp_drid
	,input	SC_disp_mask_type	c0_l2d_3todr_disp_mask
	,input	SC_dcmd_type		c0_l2d_3todr_disp_dcmd
	,input	SC_line_type		c0_l2d_3todr_disp_line
	,input	SC_paddr_type		c0_l2d_3todr_disp_paddr

	,input	logic				c0_drtol2d_3_dack_valid
	,output	logic				c0_drtol2d_3_dack_retry
	//  ,input  I_drtol2_dack_type       c0_drtol2d_3_dack
	,input	SC_nodeid_type		c0_drtol2d_3_dack_nid
	,input	L2_reqid_type		c0_drtol2d_3_dack_l2id
`endif

  // c0 core L2D and L2I
	,input	logic				c1_l2itodr_req_valid
	,output	logic				c1_l2itodr_req_retry
	//  ,input  I_l2todr_req_type        c1_l2itodr_req
	,input	SC_nodeid_type		c1_l2itodr_req_nid
	,input	L2_reqid_type		c1_l2itodr_req_l2id
	,input	SC_cmd_type			c1_l2itodr_req_cmd
	,input	SC_paddr_type		c1_l2itodr_req_paddr

	,output	logic				c1_drtol2i_snack_valid
	,input	logic				c1_drtol2i_snack_retry
	//  ,output I_drtol2_snack_type      c1_drtol2i_snack
	,output	SC_nodeid_type		c1_drtol2i_snack_nid
	,output	L2_reqid_type		c1_drtol2i_snack_l2id
	,output	DR_reqid_type		c1_drtol2i_snack_drid
	,output	SC_snack_type		c1_drtol2i_snack_snack
	,output	SC_line_type		c1_drtol2i_snack_line
	,output	SC_paddr_type		c1_drtol2i_snack_paddr

	,output	logic				c1_drtol2i_snoop_ack_valid
	,input	logic				c1_drtol2i_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c1_drtol2i_snoop_ack
	,output	L2_reqid_type		c1_drtol2i_snoop_ack_l2id

	,input	logic				c1_l2itodr_disp_valid
	,output	logic				c1_l2itodr_disp_retry
	//  ,input  I_l2todr_disp_type       c1_l2itodr_disp
	,input	SC_nodeid_type		c1_l2itodr_disp_nid
	,input	L2_reqid_type		c1_l2itodr_disp_l2id
	,input	DR_reqid_type		c1_l2itodr_disp_drid
	,input	SC_disp_mask_type	c1_l2itodr_disp_mask
	,input	SC_dcmd_type		c1_l2itodr_disp_dcmd
	,input	SC_line_type		c1_l2itodr_disp_line
	,input	SC_paddr_type		c1_l2itodr_disp_paddr

	,input	logic				c1_drtol2i_dack_valid
	,output	logic				c1_drtol2i_dack_retry
	//  ,input  I_drtol2_dack_type       c1_drtol2i_dack
	,input	SC_nodeid_type		c1_drtol2i_dack_nid
	,input	L2_reqid_type		c1_drtol2i_dack_l2id

  // L2D_0
	,input	logic				c1_l2d_0todr_req_valid
	,output	logic				c1_l2d_0todr_req_retry
	//  ,input  I_l2todr_req_type        c1_l2d_0todr_req
	,input	SC_nodeid_type		c1_l2d_0todr_req_nid
	,input	L2_reqid_type		c1_l2d_0todr_req_l2id
	,input	SC_cmd_type			c1_l2d_0todr_req_cmd
	,input	SC_paddr_type		c1_l2d_0todr_req_paddr

	,output	logic				c1_drtol2d_0_snack_valid
	,input	logic				c1_drtol2d_0_snack_retry
	//  ,output I_drtol2_snack_type      c1_drtol2d_0_snack
	,output	SC_nodeid_type		c1_drtol2d_0_snack_nid
	,output	L2_reqid_type		c1_drtol2d_0_snack_l2id
	,output	DR_reqid_type		c1_drtol2d_0_snack_drid
	,output	SC_snack_type		c1_drtol2d_0_snack_snack
	,output	SC_line_type		c1_drtol2d_0_snack_line
	,output	SC_paddr_type		c1_drtol2d_0_snack_paddr

	,output	logic				c1_drtol2d_0_snoop_ack_valid
	,input	logic				c1_drtol2d_0_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c1_drtol2d_0_snoop_ack
	,output	L2_reqid_type		c1_drtol2d_0_snoop_ack_l2id

	,input	logic				c1_l2d_0todr_disp_valid
	,output	logic				c1_l2d_0todr_disp_retry
	//  ,input  I_l2todr_disp_type       c1_l2d_0todr_disp
	,input	SC_nodeid_type		c1_l2d_0todr_disp_nid
	,input	L2_reqid_type		c1_l2d_0todr_disp_l2id
	,input	DR_reqid_type		c1_l2d_0todr_disp_drid
	,input	SC_disp_mask_type	c1_l2d_0todr_disp_mask
	,input	SC_dcmd_type		c1_l2d_0todr_disp_dcmd
	,input	SC_line_type		c1_l2d_0todr_disp_line
	,input	SC_paddr_type		c1_l2d_0todr_disp_paddr

	,input	logic				c1_drtol2d_0_dack_valid
	,output	logic				c1_drtol2d_0_dack_retry
	//  ,input  I_drtol2_dack_type       c1_drtol2d_0_dack
	,input	SC_nodeid_type		c1_drtol2d_0_dack_nid
	,input	L2_reqid_type		c1_drtol2d_0_dack_l2id

  // L2D_1
	,input	logic				c1_l2d_1todr_req_valid
	,output	logic				c1_l2d_1todr_req_retry
	//  ,input  I_l2todr_req_type        c1_l2d_1todr_req
	,input	SC_nodeid_type		c1_l2d_1todr_req_nid
	,input	L2_reqid_type		c1_l2d_1todr_req_l2id
	,input	SC_cmd_type			c1_l2d_1todr_req_cmd
	,input	SC_paddr_type		c1_l2d_1todr_req_paddr

	,output	logic				c1_drtol2d_1_snack_valid
	,input	logic				c1_drtol2d_1_snack_retry
	//  ,output I_drtol2_snack_type      c1_drtol2d_1_snack
	,output	SC_nodeid_type		c1_drtol2d_1_snack_nid
	,output	L2_reqid_type		c1_drtol2d_1_snack_l2id
	,output	DR_reqid_type		c1_drtol2d_1_snack_drid
	,output	SC_snack_type		c1_drtol2d_1_snack_snack
	,output	SC_line_type		c1_drtol2d_1_snack_line
	,output	SC_paddr_type		c1_drtol2d_1_snack_paddr

	,output	logic				c1_drtol2d_1_snoop_ack_valid
	,input	logic				c1_drtol2d_1_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c1_drtol2d_1_snoop_ack
	,output	L2_reqid_type		c1_drtol2d_1_snoop_ack_l2id

	,input	logic				c1_l2d_1todr_disp_valid
	,output	logic				c1_l2d_1todr_disp_retry
	//  ,input  I_l2todr_disp_type       c1_l2d_1todr_disp
	,input	SC_nodeid_type		c1_l2d_1todr_disp_nid
	,input	L2_reqid_type		c1_l2d_1todr_disp_l2id
	,input	DR_reqid_type		c1_l2d_1todr_disp_drid
	,input	SC_disp_mask_type	c1_l2d_1todr_disp_mask
	,input	SC_dcmd_type		c1_l2d_1todr_disp_dcmd
	,input	SC_line_type		c1_l2d_1todr_disp_line
	,input	SC_paddr_type		c1_l2d_1todr_disp_paddr

	,input	logic				c1_drtol2d_1_dack_valid
	,output	logic				c1_drtol2d_1_dack_retry
	//  ,input  I_drtol2_dack_type       c1_drtol2d_1_dack
	,input	SC_nodeid_type		c1_drtol2d_1_dack_nid
	,input	L2_reqid_type		c1_drtol2d_1_dack_l2id

`ifdef SC_4PIPE
  // l2d_2
	,input	logic				c1_l2d_2todr_req_valid
	,output	logic				c1_l2d_2todr_req_retry
	//  ,input  I_l2todr_req_type        c1_l2d_2todr_req
	,input	SC_nodeid_type		c1_l2d_2todr_req_nid
	,input	L2_reqid_type		c1_l2d_2todr_req_l2id
	,input	SC_cmd_type			c1_l2d_2todr_req_cmd
	,input	SC_paddr_type		c1_l2d_2todr_req_paddr

	,output	logic				c1_drtol2d_2_snack_valid
	,input	logic				c1_drtol2d_2_snack_retry
	//  ,output I_drtol2_snack_type      c1_drtol2d_2_snack
	,output	SC_nodeid_type		c1_drtol2d_2_snack_nid
	,output	L2_reqid_type		c1_drtol2d_2_snack_l2id
	,output	DR_reqid_type		c1_drtol2d_2_snack_drid
	,output	SC_snack_type		c1_drtol2d_2_snack_snack
	,output	SC_line_type		c1_drtol2d_2_snack_line
	,output	SC_paddr_type		c1_drtol2d_2_snack_paddr

	,output	logic				c1_drtol2d_2_snoop_ack_valid
	,input	logic				c1_drtol2d_2_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c1_drtol2d_2_snoop_ack
	,output	L2_reqid_type		c1_drtol2d_2_snoop_ack_l2id

	,input	logic				c1_l2d_2todr_disp_valid
	,output	logic				c1_l2d_2todr_disp_retry
	//  ,input  I_l2todr_disp_type       c1_l2d_2todr_disp
	,input	SC_nodeid_type		c1_l2d_2todr_disp_nid
	,input	L2_reqid_type		c1_l2d_2todr_disp_l2id
	,input	DR_reqid_type		c1_l2d_2todr_disp_drid
	,input	SC_disp_mask_type	c1_l2d_2todr_disp_mask
	,input	SC_dcmd_type		c1_l2d_2todr_disp_dcmd
	,input	SC_line_type		c1_l2d_2todr_disp_line
	,input	SC_paddr_type		c1_l2d_2todr_disp_paddr

	,input	logic				c1_drtol2d_2_dack_valid
	,output	logic				c1_drtol2d_2_dack_retry
	//  ,input  I_drtol2_dack_type       c1_drtol2d_2_dack
	,input	SC_nodeid_type		c1_drtol2d_2_dack_nid
	,input	L2_reqid_type		c1_drtol2d_2_dack_l2id

  // l2d_3
	,input	logic				c1_l2d_3todr_req_valid
	,output	logic				c1_l2d_3todr_req_retry
	//  ,input  I_l2todr_req_type        c1_l2d_3todr_req
	,input	SC_nodeid_type		c1_l2d_3todr_req_nid
	,input	L2_reqid_type		c1_l2d_3todr_req_l2id
	,input	SC_cmd_type			c1_l2d_3todr_req_cmd
	,input	SC_paddr_type		c1_l2d_3todr_req_paddr

	,output	logic				c1_drtol2d_3_snack_valid
	,input	logic				c1_drtol2d_3_snack_retry
	//  ,output I_drtol2_snack_type      c1_drtol2d_3_snack
	,output	SC_nodeid_type		c1_drtol2d_3_snack_nid
	,output	L2_reqid_type		c1_drtol2d_3_snack_l2id
	,output	DR_reqid_type		c1_drtol2d_3_snack_drid
	,output	SC_snack_type		c1_drtol2d_3_snack_snack
	,output	SC_line_type		c1_drtol2d_3_snack_line
	,output	SC_paddr_type		c1_drtol2d_3_snack_paddr

	,output	logic				c1_drtol2d_3_snoop_ack_valid
	,input	logic				c1_drtol2d_3_snoop_ack_retry
	//  ,output I_l2snoop_ack_type       c1_drtol2d_3_snoop_ack
	,output	L2_reqid_type		c1_drtol2d_3_snoop_ack_l2id

	,input	logic				c1_l2d_3todr_disp_valid
	,output	logic				c1_l2d_3todr_disp_retry
	//  ,input  I_l2todr_disp_type       c1_l2d_3todr_disp
	,input	SC_nodeid_type		c1_l2d_3todr_disp_nid
	,input	L2_reqid_type		c1_l2d_3todr_disp_l2id
	,input	DR_reqid_type		c1_l2d_3todr_disp_drid
	,input	SC_disp_mask_type	c1_l2d_3todr_disp_mask
	,input	SC_dcmd_type		c1_l2d_3todr_disp_dcmd
	,input	SC_line_type		c1_l2d_3todr_disp_line
	,input	SC_paddr_type		c1_l2d_3todr_disp_paddr

	,input	logic				c1_drtol2d_3_dack_valid
	,output	logic				c1_drtol2d_3_dack_retry
	//  ,input  I_drtol2_dack_type       c1_drtol2d_3_dack
	,input	SC_nodeid_type		c1_drtol2d_3_dack_nid
	,input	L2_reqid_type		c1_drtol2d_3_dack_l2id
`endif

	,input	logic				l2todr_req_valid
	,output	logic				l2todr_req_retry
	//  ,input  I_l2todr_req_type        l2todr_req
	,input	SC_nodeid_type		l2todr_req_nid
	,input	L2_reqid_type		l2todr_req_l2id
	,input	SC_cmd_type			l2todr_req_cmd
	,input	SC_paddr_type		l2todr_req_paddr

	,output	logic				drtol2_snack_valid
	,input	logic				drtol2_snack_retry
	//  ,output I_drtol2_snack_type      drtol2_snack
	,output	SC_nodeid_type		drtol2_snack_nid
	,output	L2_reqid_type		drtol2_snack_l2id
	,output	DR_reqid_type		drtol2_snack_drid
	,output	SC_snack_type		drtol2_snack_snack
	,output	SC_line_type		drtol2_snack_line
	,output	SC_paddr_type		drtol2_snack_paddr

	,input	logic				l2todr_disp_valid
	,output	logic				l2todr_disp_retry
	//  ,input  I_l2todr_disp_type       l2todr_disp
	,input	SC_nodeid_type		l2todr_disp_nid
	,input	L2_reqid_type		l2todr_disp_l2id
	,input	DR_reqid_type		l2todr_disp_drid
	,input	SC_disp_mask_type	l2todr_disp_mask
	,input	SC_dcmd_type		l2todr_disp_dcmd
	,input	SC_line_type		l2todr_disp_line
	,input	SC_paddr_type		l2todr_disp_paddr

	,output	logic				drtol2_dack_valid
	,input	logic				drtol2_dack_retry
	//  ,output I_drtol2_dack_type       drtol2_dack
	,output	SC_nodeid_type		drtol2_dack_nid
	,output	L2_reqid_type		drtol2_dack_l2id

	,output	logic				l2todr_snoop_ack_valid
	,input	logic				l2todr_snoop_ack_retry
	//  ,output I_drsnoop_ack_type       l2todr_snoop_ack
	,output	DR_reqid_type		l2todr_snoop_ack_drid
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
  );

  // Connect L2s to directory using a ring or switch topology

endmodule

