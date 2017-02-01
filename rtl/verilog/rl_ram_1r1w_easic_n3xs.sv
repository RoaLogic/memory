/////////////////////////////////////////////////////////////////
//                                                             //
//    ██████╗  ██████╗  █████╗                                 //
//    ██╔══██╗██╔═══██╗██╔══██╗                                //
//    ██████╔╝██║   ██║███████║                                //
//    ██╔══██╗██║   ██║██╔══██║                                //
//    ██║  ██║╚██████╔╝██║  ██║                                //
//    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝                                //
//          ██╗      ██████╗  ██████╗ ██╗ ██████╗              //
//          ██║     ██╔═══██╗██╔════╝ ██║██╔════╝              //
//          ██║     ██║   ██║██║  ███╗██║██║                   //
//          ██║     ██║   ██║██║   ██║██║██║                   //
//          ███████╗╚██████╔╝╚██████╔╝██║╚██████╗              //
//          ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝ ╚═════╝              //
//                                                             //
//    eASIC Nextreme-3S 1R1W RAM                               //
//                                                             //
/////////////////////////////////////////////////////////////////
//                                                             //
//    Copyright (C) 2016-2017 ROA Logic BV                     //
//    www.roalogic.com                                         //
//                                                             //
//   This source file may be used and distributed without      //
// restriction provided that this copyright statement is not   //
// removed from the file and that any derivative work contains //
// the original copyright notice and the associated disclaimer.//
//                                                             //
//     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     //
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   //
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   //
// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      //
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         //
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    //
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   //
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        //
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  //
// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  //
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  //
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         //
// POSSIBILITY OF SUCH DAMAGE.                                 //
//                                                             //
/////////////////////////////////////////////////////////////////
 

module rl_ram_1r1w_easic_n3xs #(
  parameter ABITS      = 8,
  parameter DBITS      = 8
)
(
  input                        rstn,
  input                        clk,
 
  //Write side
  input      [ ABITS     -1:0] waddr,
  input      [ DBITS     -1:0] din,
  input                        we,
  input      [(DBITS+7)/8-1:0] be,

  //Read side
  input      [ ABITS     -1:0] raddr,
  input                        re,
  output reg [ DBITS     -1:0] dout
);

  localparam DEPTH = 2**ABITS;
  localparam WIDTH = DBITS;


  logic [DBITS-1:0] biten;
  genvar i;

generate
  for (i=0;i<DBITS;i++)
  begin: gen_bitena
      assign biten[i] = be[i/8];
  end
endgenerate

generate
  /*
   * Nextreme-3S supports two types of bRAMs
   * -bRAM18k
   * -bRAM2k (aka RF)
   *
   * Configurations
   * bRAM18K        bRAM2K
   * 16k x  1        2k x  1
   *  8k x  2        1k x  2
   *  4k x  4       512 x  4
   *  2k x  8       256 x  8
   *  1k x 16       128 x 16 (sdp_array)
   * 512 x 32
   *
   *  2k x  9
   *  1k x 18
   * 512 x 36
   */
  if (DEPTH * WIDTH <= 4096)
  begin
      //bRAM2k
      eip_n3xs_rfile_array #(
        .WIDTHA    ( DBITS    ),
        .WIDTHB    ( DBITS    ),
        .DEPTHA    ( 2**ABITS ),
        .DEPTHB    ( 2**ABITS ),
        .REG_OUTB  ( "NO"     ),
        .TARGET    ( "POWER"  ) )
      ram_inst (
        .CLKA   ( clk           ),
        .AA     ( raddr         ),
        .DA     ( {DBITS{1'b0}} ),
        .QA     ( dout          ),
        .MEA    ( re            ),
        .WEA    ( 1'b0          ),
        .BEA    ( {DBITS{1'b1}} ),
        .RSTA_N ( 1'b1          ),

        .CLKB   ( clk           ),
        .AB     ( waddr         ),
        .DB     ( din           ),
        .QB     (               ),
        .MEB    ( 1'b1          ),
        .WEB    ( we            ),
        .BEB    ( biten         ),
        .RSTB_N ( 1'b1          ),

        .SD     ( 1'b0          ),
        .DS     ( 1'b0          ),
        .LS     ( 1'b0          ) );
  end
  else
  begin
      //bRAM18k
      eip_n3xs_bram_array #(
        .WIDTHA    ( DBITS    ),
        .WIDTHB    ( DBITS    ),
        .DEPTHA    ( 2**ABITS ),
        .DEPTHB    ( 2**ABITS ),
        .REG_OUTB  ( "NO"     ),
        .TARGET    ( "POWER"  ) )
      ram_inst (
        .CLKA   ( clk           ),
        .AA     ( raddr         ),
        .DA     ( {DBITS{1'b0}} ),
        .QA     ( dout          ),
        .MEA    ( re            ),
        .WEA    ( 1'b0          ),
        .BEA    ( {DBITS{1'b1}} ),
        .RSTA_N ( 1'b1          ),

        .CLKB   ( clk           ),
        .AB     ( waddr         ),
        .DB     ( din           ),
        .QB     (               ),
        .MEB    ( 1'b1          ),
        .WEB    ( we            ),
        .BEB    ( biten         ),
        .RSTB_N ( 1'b1          ),

        .SD     ( 1'b0          ),
        .DS     ( 1'b0          ),
        .LS     ( 1'b0          ) );
end

endgenerate

endmodule


