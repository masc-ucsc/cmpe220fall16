
`define	 SETS	  	  32
`define  WAYS	  	  8
`define  TAGBITS  	  18
`define  SET_INDEX_BITS   5
`define  WAY_BITS 	  3
`define  CACHE_STATE  	  3

//Cache States 3 bits

`define  M  	3'b000
`define  E  	3'b001
`define  S  	3'b010
`define  I  	3'b011
`define  US  	3'b100
`define  UM  	3'b101
`define  LOCK  	3'b110
`define  MARK  	3'b111

`define DC 2'b00
`define L2 2'b01
`define DCTLB 2'b10
`define MAINTLB 2'b11

//module load_yes( 


