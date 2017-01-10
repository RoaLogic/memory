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
//    eASIC Nextreme-3 1RW RAM                                 //
//                                                             //
/////////////////////////////////////////////////////////////////
//                                                             //
//    Copyright (C) 2016 ROA Logic BV                          //
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


module rl_ram_1rw_easic_n3x #(
  parameter ABITS      = 10,
  parameter DBITS      = 32
)
(
  input                    rstn,
  input                    clk,

  input  [ ABITS     -1:0] addr,
  input                    we,
  input  [(DBITS+7)/8-1:0] be,
  input  [ DBITS     -1:0] din,
  output [ DBITS     -1:0] dout
);

  eip_n3x_bram_sp_array #(
    .WIDTH         ( DBITS    ),
    .DEPTH         ( 2**ABITS ),
    .REG_OUT       ( "NO"     ),
    .INIT_ON       ( "NO"     ),
    .NINE_BIT_MODE ( "AUTO"   ),
    .TARGET        ( "POWER"  ) )
  ram_inst (
    .CLK    ( clk           ),
    .A      ( addr          ),
    .D      ( din           ),
    .Q      ( dout          ),
    .ME     ( 1'b1          ),
    .WE     ( we            ),
    .BE     ( {DBITS{1'b1}} ),
    .RST_N  ( 1'b1          ),

    .SD     ( 1'b0          ),
    .DS     ( 1'b0          ),
    .LS     ( 1'b0          ) );
endmodule


