/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    Single Clock FIFO                                            //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2023 ROA Logic BV                     //
//             www.roalogic.com                                    //
//                                                                 //
//     Unless specifically agreed in writing, this software is     //
//   licensed under the RoaLogic Non-Commercial License            //
//   version-1.0 (the "License"), a copy of which is included      //
//   with this file or may be found on the RoaLogic website        //
//   http://www.roalogic.com. You may not use the file except      //
//   in compliance with the License.                               //
//                                                                 //
//     THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY           //
//   EXPRESS OF IMPLIED WARRANTIES OF ANY KIND.                    //
//   See the License for permissions and limitations under the     //
//   License.                                                      //
//                                                                 //
/////////////////////////////////////////////////////////////////////

// +FHDR -  Semiconductor Reuse Standard File Header Section  -------
// FILE NAME      : scfifo.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2023-11-09  rherveille  initial release
// ------------------------------------------------------------------
// KEYWORDS : FIFO
// ------------------------------------------------------------------
// PURPOSE  : Single Clock FIFO
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE    DESCRIPTION              DEFAULT UNITS
//  INIT_DLY_CNT      1+       Powerup delay            2500    cycles
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : rst_ni, asynchronous, active low
//   Clock Domains       : clk_i
//   Critical Timing     : 
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : na
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------


module rl_scfifo
#(
  parameter int DEPTH             = 16,
  parameter int DATA_SIZE         = 32,
  parameter int WR_DATA_SIZE      = DATA_SIZE,
  parameter int RD_DATA_SIZE      = DATA_SIZE,
  parameter     TECHNOLOGY        = "GENERIC",
  parameter     REGISTERED_OUTPUT = "NO",

  parameter int FIFO_DEPTH = max(DEPTH, 1 << $clog2(DEPTH)),
  parameter int PTR_SIZE   = $clog2(FIFO_DEPTH)
)
(
  input  logic                    rst_ni,
  input  logic                    clk_i,
  input  logic                    clr_i,

  input  logic [WR_DATA_SIZE-1:0] d_i,
  input  logic                    wrena_i,

  input  logic                    rdena_i,
  output logic [RD_DATA_SIZE-1:0] q_o,

  output logic                    empty_o,
  output logic                    full_o,
  output logic [PTR_SIZE      :0] usedw_o
);
  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //
  function int max(input int a, input int b);
    max = a > b ? a : b;
  endfunction : max

  function is_power_of_2(input int n);
    is_power_of_2 = (n & (n-1)) == 0;
  endfunction


  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam int RDWR_RATIO = max(RD_DATA_SIZE / WR_DATA_SIZE, 1);
  localparam int WRRD_RATIO = max(WR_DATA_SIZE / RD_DATA_SIZE,  1);

  localparam int SEL_RD     = RDWR_RATIO > WRRD_RATIO;

  localparam int RATIO      = SEL_RD ? RDWR_RATIO    : WRRD_RATIO;


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  logic                  wrena, rdena;  
  logic [PTR_SIZE  -1:0] nxt_wrptr, wrptr,
                         nxt_rdptr, rdptr;
  logic [DATA_SIZE -1:0] dout;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  initial
  begin
      if ( !is_power_of_2(RATIO) )
      begin
          $error("Ratio between read and write ports must be a power of 2");
          $finish;
      end
  end


  /* Safeguard write and read signals
   */
  assign wrena = wrena_i & ~full_o;
  assign rdena = rdena_i & ~empty_o;


  /* Pointers
   */
  assign nxt_wrptr = wrptr +1'h1;
  assign nxt_rdptr = rdptr +1'h1;

  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) wrptr <= {PTR_SIZE{1'b0}};
    else if ( clr_i ) wrptr <= {PTR_SIZE{1'b0}};
    else if ( wrena ) wrptr <= nxt_wrptr;


  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) rdptr <= {PTR_SIZE{1'b0}};
    else if ( clr_i ) rdptr <= {PTR_SIZE{1'b0}};
    else if ( rdena ) rdptr <= nxt_rdptr;


  /* Hookup memory
   */
  rl_ram_1r1w #(
    .ABITS         ( PTR_SIZE          ),
    .DBITS         ( DATA_SIZE         ),
    .TECHNOLOGY    ( TECHNOLOGY        ),
    .INIT_FILE     ( ""                ),
    .RW_CONTENTION ("BYPASS"           ))
  memory (
    .rst_ni  ( rst_ni                  ),
    .clk_i   ( clk_i                   ),
 
    //Write side
    .waddr_i ( wrptr                   ),
    .din_i   ( d_i                     ),
    .we_i    ( wrena                   ),
    .be_i    ( {(DATA_SIZE+7)/8{1'b1}} ),

    //Read side
    .raddr_i ( rdptr                   ),
    .re_i    ( rdena                   ),
    .dout_o  ( dout                    ));


  /* Output
   */
generate

  if (REGISTERED_OUTPUT != "NO")
    always @(posedge clk_i)
      q_o <= dout;
  else
    assign q_o = dout;

endgenerate


  /* Flags
   */
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) empty_o <= 1'b1;
    else if ( clr_i ) empty_o <= 1'b1;
    else
      case ({wrena,rdena})
        2'b00: ; //NOP
        2'b01: empty_o <= nxt_rdptr == wrptr;
        2'b10: empty_o <= 1'b0;
        2'b11: ; //NOP
      endcase


  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) full_o <= 1'b0;
    else if ( clr_i ) full_o <= 1'b0;
    else
      case ({wrena,rdena})
        2'b00: ; //NOP
        2'b01: full_o <= 1'b0;
        2'b10: full_o <= nxt_wrptr == rdptr;
        2'b11: ; //NOP
      endcase


  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) usedw_o <= {$bits(usedw_o){1'b0}};
    else if ( clr_i ) usedw_o <= {$bits(usedw_o){1'b0}};
    else
      case ({wrena,rdena})
        2'b00: ; //NOP
        2'b01: usedw_o <= {1'b0,                   wrptr - nxt_rdptr};
        2'b10: usedw_o <= {nxt_wrptr == rdptr, nxt_wrptr -     rdptr};
        2'b11: ; //NOP
      endcase
 
endmodule : rl_scfifo
