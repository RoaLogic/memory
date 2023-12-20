/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   Altera Specefic 1R1W RAM Memory                               //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2023 Roa Logic BV                     //
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
// FILE NAME      : rl_ram_1r1w_altera.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2023-12-19  rherveille  initial release with new logo
// ------------------------------------------------------------------
// KEYWORDS : Altera MEMORY RAM 1R1W
// ------------------------------------------------------------------
// PURPOSE  : Wrapper for Altera altsyncram
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME      RANGE  DESCRIPTION                  DEFAULT UNITS
//  ABITS           1+     Number of address bits       10      bits
//  DBITS           1+     Number of data bits          32      bits
//  READ_ABITS      1+     Number of read address bits  ABITS   bits
//  READ_DBITS      1+     Number of read data bits     DBITS   bits
//  WRITE_ABITS     1+     Number of write address bits ABITS   bits
//  WRITE_DBITS     1+     Number of write data bits    DBITS   bits
//  INIT_FILE              Path to initialisation file  ""
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : rstn_i; asynchronous, active low
//   Clock Domains       : clk_i; rising edge
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : none                     
//   Scan Methodology    : na
//   Instantiations      : Yes; altsyncram
//   Synthesizable (y/n) : Yes
//   Other               : 
// -FHDR-------------------------------------------------------------


module rl_ram_1r1w_altera #(
  parameter ABITS       = 10,
  parameter DBITS       = 32,
  parameter READ_ABITS  = ABITS,
  parameter READ_DBITS  = DBITS,
  parameter WRITE_ABITS = ABITS,
  parameter WRITE_DBITS = DBITS,
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
  output     [ READ_DBITS      -1:0] dout_o
);

  /*
   * Instantiate Altera altsycram
   */
      altsyncram #(
        .widthad_a                 ( WRITE_ABITS    ),
        .width_a                   ( WRITE_DBITS    ),
        .width_byteena_a           ( WRITE_DBITS/8  ),
        .address_aclr_a            ( "NONE"         ),
        .wrcontrol_aclr_a          ( "NONE"         ),
        .byteena_aclr_a            ( "NONE"         ),
        .indata_aclr_a             ( "NONE"         ),
        .outdata_aclr_a            ( "NONE"         ),
        .outdata_reg_a             ( "UNREGISTERED" ),

        .widthad_b                 ( READ_ABITS     ),
        .width_b                   ( READ_DBITS     ),
        .width_byteena_b           ( READ_DBITS/8   ),
        .address_aclr_b            ( "NONE"         ),
        .wrcontrol_aclr_b          ( "NONE"         ),
        .byteena_aclr_b            ( "NONE"         ),
        .indata_aclr_b             ( "NONE"         ),
        .outdata_aclr_b            ( "NONE"         ),
        .outdata_reg_b             ( "UNREGISTERED" ),
        .address_reg_b             ( "CLOCK1"       ),
        .indata_reg_b              ( "CLOCK1"       ),
        .wrcontrol_wraddress_reg_b ( "CLOCK1"       ),
        .byteena_reg_b             ( "CLOCK1"       ),
        .rdcontrol_reg_b           ( "CLOCK1"       ),

        .init_file                 ( INIT_FILE      ),
        .enable_ecc                ( "FALSE"        ),
        .power_up_uninitialized    ( "TRUE"         ),
        .read_during_write_mode_mixed_ports ("DONT_CARE"),
        .ram_block_type            ( "AUTO"         )
      )
      ram_inst (
`ifndef ALTERA_RESERVED_QIS
        .aclr0          ( rst_ni               ),
        .aclr1          ( rst_ni               ),
`endif

        .clock0         ( clk_i                ),
        .clock1         ( clk_i                ),
        .clocken0       ( 1'b1                 ),
        .clocken1       ( 1'b1                 ),
        .clocken2       ( 1'b1                 ),
        .clocken3       ( 1'b1                 ),

        //write port
        .address_a      ( waddr_i              ),
        .addressstall_a ( 1'b0                 ),
        .data_a         ( din_i                ),
        .byteena_a      ( be_i                 ),
        .wren_a         ( we_i                 ),
        .rden_a         ( 1'b0                 ),
        .q_a            ( ),

        //read port
        .address_b      ( raddr_i              ),
        .addressstall_b ( 1'b0                 ),
        .data_b         ( {READ_DBITS  {1'b0}} ),
        .byteena_b      ( {READ_DBITS/8{1'b1}} ),
        .wren_b         ( 1'b0                 ),
        .rden_b         ( 1'b1                 ),
        .q_b            ( dout_o               ),

        .eccstatus      ( )
      );
 
endmodule
