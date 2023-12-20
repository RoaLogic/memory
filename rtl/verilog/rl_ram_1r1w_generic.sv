/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   Technology Independent (Inferrable) Memory Wrapper            //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2014-2018 Roa Logic BV                //
//             www.roalogic.com                                    //
//                                                                 //
//   This source file may be used and distributed without          //
//   restriction provided that this copyright statement is not     //
//   removed from the file and that any derivative work contains   //
//   the original copyright notice and the associated disclaimer.  //
//                                                                 //
//      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        //
//   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     //
//   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     //
//   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR OR     //
//   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  //
//   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  //
//   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  //
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      //
//   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     //
//   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  //
//   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS          //
//   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  //
//                                                                 //
/////////////////////////////////////////////////////////////////////

// +FHDR -  Semiconductor Reuse Standard File Header Section  -------
// FILE NAME      : rl_ram_1r1w_generic.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2018-07-27  rherveille  initial release with new logo
// ------------------------------------------------------------------
// KEYWORDS : Generic Inferrable FPGA MEMORY RAM 1R1W
// ------------------------------------------------------------------
// PURPOSE  : Wrapper for inferrable 1R1W RAM Blocks
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  ABITS             1+     Number of address bits   10      bits
//  DBITS             1+     Number of data bits      32      bits
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : rstn_i; asynchronous, active low
//   Clock Domains       : clk_i; rising edge
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : none                     
//   Scan Methodology    : na
//   Instantiations      : No
//   Synthesizable (y/n) : Yes
//   Other               : 
// -FHDR-------------------------------------------------------------


module rl_ram_1r1w_generic #(
  parameter ABITS       = 10,
  parameter DBITS       = 32,
  parameter WRITE_ABITS = ABITS,
  parameter WRITE_DBITS = DBITS,
  parameter READ_ABITS  = ABITS,
  parameter READ_DBITS  = DBITS,
  parameter INIT_FILE   = ""
)
(
  input                              rst_ni,
  input                              clk_i,

  //Write side
  input      [ WRITE_ABITS     -1:0] waddr_i,
  input      [ WRITE_DBITS     -1:0] din_i,
  input                              we_i,
  input      [(WRITE_DBITS+7)/8-1:0] be_i,

  //Read side
  input      [ READ_ABITS      -1:0] raddr_i,
  output reg [ READ_DBITS      -1:0] dout_o
);

  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //
  function is_power_of_2(input int n);
    is_power_of_2 = (n & (n-1)) == 0;
  endfunction

  function int max(input int a, input int b);
    max = a > b ? a : b;
  endfunction : max


  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //

  localparam int RDWR_RATIO = max(READ_DBITS  / WRITE_DBITS, 1);
  localparam int WRRD_RATIO = max(WRITE_DBITS / READ_DBITS,  1);

  localparam int SEL_RD     = RDWR_RATIO > WRRD_RATIO;

  localparam int RATIO      = SEL_RD ? RDWR_RATIO    : WRRD_RATIO;
  localparam int RAM_DBITS  = SEL_RD ? WRITE_DBITS   : READ_DBITS;
  localparam int RAM_DEPTH  = SEL_RD ? 2**READ_ABITS : 2**WRITE_ABITS;
  localparam int RAM_BANKS  = SEL_RD ? 2**(WRITE_ABITS - READ_ABITS) : 2**(READ_ABITS - WRITE_ABITS);

  localparam int RD_TOTAL_BITS = 2**READ_ABITS  * READ_DBITS;
  localparam int WR_TOTAL_BITS = 2**WRITE_ABITS * WRITE_DBITS;


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  genvar i;

  logic [RAM_BANKS-1:0][RAM_DBITS-1:0] mem_array [RAM_DEPTH];  //memory array


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  initial
  begin
      //preload memory
      //This seems to be synthesizable in FPGAs
      if (INIT_FILE != "")
      begin
          $display ("INFO   : Loading %s (%m)", INIT_FILE);
          $readmemh(INIT_FILE, mem_array);
      end

      //Checks
      if (RD_TOTAL_BITS != WR_TOTAL_BITS)
      begin
          $error("Total number of read port bits (%0d) is not equal to the total number of write port bits(%0d) (%m)", RD_TOTAL_BITS, WR_TOTAL_BITS);
          $finish;
      end

      if ( !is_power_of_2(RATIO) )
      begin
          $error("Ratio between read and write ports must be a power of 2");
          $finish;
      end
  end

  /*
   * write side
   */
generate
  if (SEL_RD)
  begin
      /* Write
       */
      for (i=0; i<(WRITE_DBITS+7)/8; i++)
      begin: write
         if (i*8 +8 > WRITE_DBITS)
         begin
             always @(posedge clk_i)
               if (we_i && be_i[i])
                 mem_array[waddr_i / RDWR_RATIO][waddr_i % RDWR_RATIO][WRITE_DBITS-1:i*8] <= din_i[WRITE_DBITS-1:i*8];
         end
         else
         begin
             always @(posedge clk_i)
               if (we_i && be_i[i])
                 mem_array[waddr_i /RDWR_RATIO][waddr_i % RDWR_RATIO][i*8+:8] <= din_i[i*8+:8];
         end
      end

      /* Read
       */
      //per Altera's recommendations. Prevents bypass logic
      always @(posedge clk_i)
        dout_o <= mem_array[raddr_i / WRRD_RATIO];
  end
  else
  begin
      /* Write
       */
      for (i=0; i<(WRITE_DBITS+7)/8; i++)
      begin: write
         if (i*8 +8 > WRITE_DBITS)
         begin
             always @(posedge clk_i)
               if (we_i && be_i[i])
                 mem_array[waddr_i / RDWR_RATIO][waddr_i % RDWR_RATIO][WRITE_DBITS-1:i*8] <= din_i[WRITE_DBITS-1:i*8];
         end
         else
         begin
             always @(posedge clk_i)
               if (we_i && be_i[i])
                 mem_array[waddr_i /RDWR_RATIO][waddr_i % RDWR_RATIO][i*8+:8] <= din_i[i*8+:8];
         end
      end

      /* Read
       */
      //per Altera's recommendations. Prevents bypass logic
      always @(posedge clk_i)
        dout_o <= mem_array[raddr_i / WRRD_RATIO][raddr_i % WRRD_RATIO];
  end
endgenerate
endmodule


