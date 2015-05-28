/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2008 Xilinx, Inc.  All rights reserved.
//
//                 XILINX CONFIDENTIAL PROPERTY
// This   document  contains  proprietary information  which   is
// protected by  copyright. All rights  are reserved.  This notice
// refers to original work by Xilinx, Inc. which may be derivitive
// of other work distributed under license of the authors.  In the
// case of derivitive work, nothing in this notice overrides the
// original author's license agreeement.  Where applicable, the 
// original license agreement is included in it's original 
// unmodified form immediately below this header.
//
// Xilinx, Inc.
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE.
//
/////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE Connection Matrix Priority Decoder                ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/wb_conmax/ ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: wb_conmax_pri_dec.v,v 1.1 2008/05/07 22:43:23 daughtry Exp $
//
//  $Date: 2008/05/07 22:43:23 $
//  $Revision: 1.1 $
//  $Author: daughtry $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: wb_conmax_pri_dec.v,v $
//               Revision 1.1  2008/05/07 22:43:23  daughtry
//               Initial Demo RTL check-in
//
//               Revision 1.2  2002/10/03 05:40:07  rudi
//               Fixed a minor bug in parameter passing, updated headers and specification.
//
//               Revision 1.1.1.1  2001/10/19 11:01:42  rudi
//               WISHBONE CONMAX IP Core
//
//
//
//
//

`include "wb_conmax_defines.v"

module wb_conmax_pri_dec(valid, pri_in, pri_out);

////////////////////////////////////////////////////////////////////
//
// Module Parameters
//

parameter [1:0]	pri_sel = 2'd0;

////////////////////////////////////////////////////////////////////
//
// Module IOs
//

input		valid;
input	[1:0]	pri_in;
output	[3:0]	pri_out;

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

wire	[3:0]	pri_out;
reg	[3:0]	pri_out_d0;
reg	[3:0]	pri_out_d1;

////////////////////////////////////////////////////////////////////
//
// Priority Decoder
//

// 4 Priority Levels
always @(valid or pri_in)
	if(!valid)		pri_out_d1 = 4'b0001;
	else
	if(pri_in==2'h0)	pri_out_d1 = 4'b0001;
	else
	if(pri_in==2'h1)	pri_out_d1 = 4'b0010;
	else
	if(pri_in==2'h2)	pri_out_d1 = 4'b0100;
	else			pri_out_d1 = 4'b1000;

// 2 Priority Levels
always @(valid or pri_in)
	if(!valid)		pri_out_d0 = 4'b0001;
	else
	if(pri_in==2'h0)	pri_out_d0 = 4'b0001;
	else			pri_out_d0 = 4'b0010;

// Select Configured Priority

assign pri_out = (pri_sel==2'd0) ? 4'h0 : ( (pri_sel==1'd1) ? pri_out_d0 : pri_out_d1 );

endmodule

