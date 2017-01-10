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
//    1RW (SP) RAM Block                                       //
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
 

module rl_ram_1rw #(
  parameter ABITS      = 10,
  parameter DBITS      = 32,
  parameter TECHNOLOGY = "GENERIC"
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
  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
generate

  if (TECHNOLOGY == "N3X" ||
      TECHNOLOGY == "n3x" )
  begin
      /*
       * eASIC N3X
       */
      rl_ram_1rw_easic_n3x #(
        .ABITS ( ABITS ),
        .DBITS ( DBITS ) )
      ram_inst ( .* );
  end
  else // (TECHNOLOGY == "GENERIC")
  begin
      /*
       * GENERIC  -- inferrable memory
       */
      initial $display ("INFO   : No memory technology specified. Using generic inferred memory (%m)");

      rl_ram_1rw_generic #(
        .ABITS ( ABITS ),
        .DBITS ( DBITS ) )
      ram_inst ( .* );
  end

endgenerate

endmodule


