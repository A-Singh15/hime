`timescale 1ns/1ps
`include "transaction.sv"

// ======== DEFINES ========
`define SMEM_MAX 1024
`define RMEM_MAX 256
`define TRANSACTION_COUNT 1
`define DRIV_IF memIntf.DriverInterface
`define MON_IF memIntf.MonitorInterface

// ======== ASSERTIONS ========

module MotionEstimationAssertions (
    input clk,
    input trigger,
    input [7:0] distance,
    input [3:0] vectorX,
    input [3:0] vectorY,
    input done
);

    integer signedX, signedY;

    // Convert 4-bit signed motion vectors to 5-bit signed integers
    always @(*) begin
        if (vectorX >= 8)
            signedX = vectorX - 16;
        else
            signedX = vectorX;

        if (vectorY >= 8)
            signedY = vectorY - 16;
        else
            signedY = vectorY;
    end

    always @(posedge clk) begin
        // Assertion 1: Ensure that 'done' signal is not asserted when 'trigger' is high
        assert (trigger -> !done)
        else $error("Assertion failed: trigger -> !done at time %0t", $time);

        // Assertion 2: Ensure that 'done' signal is asserted when 'trigger' is low
        assert ((!trigger && !$past(trigger)) -> done)
        else $error("Assertion failed: (!trigger && !$past(trigger)) -> done at time %0t", $time);

        // Assertion 3: Ensure that 'distance' is always within the valid range of 0x00 to 0xFF
        assert ((distance >= 8'h00) && (distance <= 8'hFF))
        else $error("Assertion failed: distance out of range at time %0t", $time);

        // Assertion 4: Ensure that 'vectorX' and 'vectorY' are valid motion vectors
        assert ((signedX >= -8) && (signedX <= 7) && (signedY >= -8) && (signedY <= 7))
        else $error("Assertion failed at time %0t: MotionX = %0d, MotionY = %0d", $time, signedX, signedY);
    end
endmodule

// ======== COVERAGE ========

class Coverage;

    // Coverage metric
    real coverageMetric;

    // Virtual interface to memory
    virtual MotionEstimationInterface memIntf;

    // Mailbox for receiving transactions from the monitor
    mailbox mon2cov;

    // Transaction object
    Transaction transactionData;
      
    // Covergroup for measuring coverage
    covergroup coverageGroup;
        option.per_instance = 1;
        
        // Coverpoint for distance
        distanceCoverpoint: coverpoint transactionData.bestDistance; // Automatic bins

        // Coverpoint for expectedXMotion with specified bins
        expectedXMotionCoverpoint: coverpoint transactionData.expectedXMotion {
            bins negativeValues[] = {[-8:-1]}; // Negative values
            bins zeroValue  = {0};             // Zero value
            bins positiveValues[] = {[1:7]};   // Positive values
        }

        // Coverpoint for expectedYMotion with specified bins
        expectedYMotionCoverpoint: coverpoint transactionData.expectedYMotion {
            bins negativeValues[] = {[-8:-1]}; // Negative values
            bins zeroValue  = {0};             // Zero value
            bins positiveValues[] = {[1:7]};   // Positive values
        }

        // Coverpoint for actualXMotion with specified bins
        actualXMotionCoverpoint: coverpoint transactionData.actualXMotion {
            bins negativeValues[] = {[-8:-1]}; // Negative values
            bins zeroValue  = {0};             // Zero value
            bins positiveValues[] = {[1:7]};   // Positive values
        }

        // Coverpoint for actualYMotion with specified bins
        actualYMotionCoverpoint: coverpoint transactionData.actualYMotion {
            bins negativeValues[] = {[-8:-1]}; // Negative values
            bins zeroValue  = {0};             // Zero value
            bins positiveValues[] = {[1:7]};   // Positive values
        }
        CrossExpected : cross expectedXMotionCoverpoint, expectedYMotionCoverpoint;
        CrossActual : cross actualXMotionCoverpoint, actualYMotionCoverpoint;
    endgroup
    
    // Constructor to initialize the coverage class
    function new(virtual MotionEstimationInterface memIntf, mailbox mon2cov);
        this.memIntf = memIntf;
        this.mon2cov = mon2cov;
        coverageGroup = new();
    endfunction
     
    // Task to continuously sample coverage
    task sampleCoverage();
        forever begin
            mon2cov.get(transactionData);        // Get a transaction from the mailbox
            coverageGroup.sample();              // Sample the covergroup
            coverageMetric = coverageGroup.get_coverage(); // Update coverage metric
        end
    endtask
    
endclass
