/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//    RISC-V                                                       //
//    Fall-through Queue                                           //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2018 ROA Logic BV                     //
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
// FILE NAME      : rl_queue.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2018-07-27  rherveille  initial release
// ------------------------------------------------------------------
// KEYWORDS : QUEUE
// ------------------------------------------------------------------
// PURPOSE  : Parameterized fall-through queue
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  DEPTH             1+     Number of queue entries  2       bits
//  DBITS             1+     Number of data bits      32      bits
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : rstn_i; asynchronous, active low
//                         clr_i; synchronous active high
//   Clock Domains       : clk_i; rising edge
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : none
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               : 
// -FHDR-------------------------------------------------------------


/*
 * Parameterized Fall-Through Queue
 * This is a stack of registers of level 'DEPTH'.
 * The output always points to level 0
 * As new data is written to the next higher available stack level
 * As data is read, the old data 'falls-through' to the next lower level
 */

module rl_queue #(
  parameter DEPTH = 2,
  parameter DBITS = 32
)
(
  input  logic             rst_ni,  //asynchronous, active low reset
  input  logic             clk_i,   //rising edge triggered clock

  input  logic             clr_i,   //clear all queue entries (synchronous reset)
  input  logic             ena_i,   //clock enable

  //Queue Write
  input  logic             we_i,    //Queue write enable
  input  logic [DBITS-1:0] d_i,     //Queue write data

  //Queue Read
  input  logic             re_i,    //Queue read enable
  output logic [DBITS-1:0] q_o,     //Queue read data

  //Status signals
  output logic             empty_o, //Queue is empty
                           full_o   //Queue is full
);


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic [DBITS        -1:0] queue_data[DEPTH];
  logic [$clog2(DEPTH)-1:0] queue_wadr;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //Write Address
  always @(posedge clk_i,negedge rst_ni)
    if      (!rst_ni) queue_wadr <= 'h0;
    else if ( clr_i ) queue_wadr <= 'h0;
    else if ( ena_i )
      unique case ({we_i,re_i})
         2'b01 : queue_wadr <= queue_wadr -1;
         2'b10 : queue_wadr <= queue_wadr +1;
         default: ;
      endcase


  //Queue Data
  always @(posedge clk_i,negedge rst_ni)
    if (!rst_ni)
      for (int n=0; n<DEPTH; n++) queue_data[n] <= 'h0;
    else if (clr_i)
      for (int n=0; n<DEPTH; n++) queue_data[n] <= 'h0;
    else if (ena_i)
    unique case ({we_i,re_i})
       2'b01  : begin
                    for (int n=0; n<DEPTH-1; n++)
                      queue_data[n] <= queue_data[n+1];

                    queue_data[DEPTH-1] <= 'h0;
                end

       2'b10  : begin
                    queue_data <= d_i;
                end

       2'b11  : begin
                    for (int n=0; n<DEPTH-1; n++)
                      queue_data[n] <= queue_data[n+1];

                    queue_data[DEPTH-1] <= 'h0;

                    queue_data[~|queue_wadr ? DEPTH-1 : queue_wadr-1] <= d_i;
                end

       default: ;
    endcase


  //Queue Full
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) full_o <= 1'b0;
    else if ( clr_i ) full_o <= 1'b0;
    else if ( ena_i )
      unique case ({we_i,re_i})
         2'b01  : full_o <= 1'b0;
         2'b10  : full_o <= (queue_wadr == DEPTH-1); //&queue_wadr;
         default: ;
      endcase


  //Queue Empty
  always @(posedge clk_i, negedge rst_ni)
    if      (!rst_ni) empty_o <= 1'b1;
    else if ( clr_i ) empty_o <= 1'b1;
    else if ( ena_i )
      unique case ({we_i,re_i})
         2'b01  : empty_o <= (queue_wadr == 1);
         2'b10  : empty_o <= 1'b0;
         default: ;
      endcase


  //Queue output data
  assign q_o = queue_data[0];

endmodule
