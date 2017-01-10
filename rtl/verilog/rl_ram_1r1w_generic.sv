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
//    Technology independent (inferrable) 1R1W RAM             //
//                                                             //
/////////////////////////////////////////////////////////////////
//                                                             //
//    Copyright (C) 2014-2016 ROA Logic BV                     //
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


module rl_ram_1r1w_generic #(
  parameter ABITS      = 10,
  parameter DBITS      = 32
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
  output reg [ DBITS     -1:0] dout
);

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  genvar i;

  logic [DBITS-1:0] mem_array [2**ABITS -1:0];  //memory array


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /*
   * write side
   */
generate
  for (i=0; i<(DBITS+7)/8; i++)
  begin: write
     if (i*8 +8 > DBITS)
     begin
         always @(posedge clk)
           if (we && be[i]) mem_array[ waddr ] [DBITS-1:i*8] <= din[DBITS-1:i*8];
     end
     else
     begin
         always @(posedge clk)
           if (we && be[i]) mem_array[ waddr ][i*8+:8] <= din[i*8+:8];
     end
  end
endgenerate

  /*
   * read side
   */
  //per Altera's recommendations. Prevents bypass logic
  always @(posedge clk)
    dout <= mem_array[ raddr ];
endmodule


