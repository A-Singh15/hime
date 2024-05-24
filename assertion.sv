`timescale 1ns/1ps

module MotionEstimationAssertions(
    input clk, 
    input trigger, 
    input [7:0] distance, 
    input [3:0] vectorX, 
    input [3:0] vectorY, 
    input done
);

  integer signedVectorX, signedVectorY;

  // Convert 4-bit unsigned motion vectors to 5-bit signed integers
  always @(*) begin
      signedVectorX = (vectorX >= 8) ? (vectorX - 16) : vectorX;
      signedVectorY = (vectorY >= 8) ? (vectorY - 16) : vectorY;
  end

  always @(posedge clk) begin
    // Assertion 1: Ensure that 'done' signal is not asserted when 'trigger' is high
    trigger_done_chk: assert property (@(posedge clk) (trigger -> !done)) else
      $error("Assertion failed: trigger -> !done at time %0t", $time);

    // Assertion 2: Ensure that 'done' signal is asserted when 'trigger' is low and was low in the previous cycle
    trigger_done_chk1: assert property (@(posedge clk) ((!trigger && !$past(trigger)) -> done)) else
      $error("Assertion failed: (!trigger && !$past(trigger)) -> done at time %0t", $time);

    // Assertion 3: Ensure that 'distance' is always within the valid range of 0x00 to 0xFF
    distance_valid_chk: assert property (@(posedge clk) disable iff (!trigger)
      ((distance >= 8'h00) && (distance <= 8'hFF))) else
      $error("Assertion failed: distance out of range at time %0t", $time);

    // Assertion 4: Ensure that 'vectorX' and 'vectorY' are valid motion vectors within the range -8 to 7
    motion_vectors_chk: assert property (@(posedge clk) disable iff (!done || !trigger)
      ((signedVectorX >= -8) && (signedVectorX <= 7) && (signedVectorY >= -8) && (signedVectorY <= 7))) else
      $error("Assertion failed at time %0t: vectorX = %0d, vectorY = %0d", $time, signedVectorX, signedVectorY);
  end

endmodule
