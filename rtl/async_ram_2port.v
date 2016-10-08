//==============================================================================
//      File:           $URL$
//      Version:        $Revision$
//      Author:         Jose Renau  (http://masc.cse.ucsc.edu/)
//      Copyright:      Copyright 2011  UC Santa Cruz
//==============================================================================

//==============================================================================
//      Section:        License
//==============================================================================
//      SCOORE: Santa Cruz Out-of-order Risc Engine
//      Copyright (C) 2004 University of California, Santa Cruz.
//      All rights reserved.
//
//      This file is part of SCOORE.
//      
//      SCOORE is free software; you can redistribute it and/or modify it under the
//      terms of the GNU General Public License as published by the Free Software
//      Foundation; either version 2, or (at your option) any later version.
//      
//      SCOORE is distributed in the  hope that  it will  be  useful, but  WITHOUT ANY
//      WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
//      PARTICULAR PURPOSE.  See the GNU General Public License for more details.
//      
//      You should  have received a copy of  the GNU General  Public License along with
//      SCOORE; see the file COPYING.  If not, write to the  Free Software Foundation,
//      59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
//
//
//      Redistribution and use in source and binary forms, with or without modification,
//      are permitted provided that the following conditions are met:
//
//              - Redistributions of source code must retain the above copyright notice,
//                      this list of conditions and the following disclaimer.
//              - Redistributions in binary form must reproduce the above copyright
//                      notice, this list of conditions and the following disclaimer
//                      in the documentation and/or other materials provided with the
//                      distribution.
//              - Neither the name of the University of California, Santa Cruz nor the
//                      names of its contributors may be used to endorse or promote
//                      products derived from this software without specific prior
//                      written permission.
//
//      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//      ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//      DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//      ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//      (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//      ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//===========================================================================
/****************************************************************************
    Description:

  Register file structure. Instantiates the optimal module based on the number
  of rd/wr ports.

  NOTE:

   This module does not have reset. Tables can be too big, the state machine to
   clear datas should be handled outside (if necessary).


****************************************************************************/

`include "logfunc.h"

module async_ram_2port
  #(parameter Width = 64, Size=128)
    ( input [`log2(Size)-1:0]  p0_pos
     ,input                    p0_enable
     ,input [Width-1:0]        p0_in_data
     ,output reg [Width-1:0]   p0_out_data

     ,input [`log2(Size)-1:0]  p1_pos
     ,input                    p1_enable
     ,input [Width-1:0]        p1_in_data
     ,output reg [Width-1:0]   p1_out_data
     );

   reg [Width-1:0]        data [Size-1:0]; // synthesis syn_ramstyle = "block_ram"
   reg [Width-1:0]        d0;
   reg [Width-1:0]        d1;

   always_comb begin
     if (p0_enable) begin
       d0 = 'bx;
     end else begin
       d0 = data[p0_pos];
     end
   end

   always_comb begin
     if (p1_enable) begin
       d1 = 'bx;
     end else begin
       d1 = data[p1_pos];
     end
   end

   always @(p0_pos or p0_in_data or p0_enable) begin
     if (p0_enable) begin
       data[p0_pos] = p0_in_data;
     end
   end

   always @(p1_pos or p1_in_data or p1_enable) begin
     if (p1_enable) begin
       data[p1_pos] = p1_in_data;
     end
   end

   always_comb begin
     p0_out_data = d0;
     p1_out_data = d1;
   end

endmodule 

