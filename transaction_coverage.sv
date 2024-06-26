`ifndef TRANSACTION_COVERAGE_SV
`define TRANSACTION_COVERAGE_SV

`timescale 1ns/1ps

`define SMEM_MAX 1024
`define RMEM_MAX 256
`define TRANSACTION_COUNT 500
`define DRIV_IF memoryInterface.DriverInterface.Driver_cb
`define MON_IF memoryInterface.MonitorInterface.Monitor_cb

class Transaction;

  // Memory arrays for reference and search data
  logic [7:0] referenceMemory[`RMEM_MAX-1:0];
  rand logic [7:0] searchMemory[`SMEM_MAX-1:0];

  // Motion vectors and best distance metrics
  rand integer expectedXMotion;
  rand integer expectedYMotion;
  integer actualXMotion;
  integer actualYMotion;
  logic [7:0] bestDistance;

  // Random index for introducing mismatches
  rand int randomMismatchIndex;
  
  // Constraints for expected motion vectors
  constraint expectedMotionConstraint { 
    expectedXMotion dist {[-8:0]:=10, [1:7]:=10};
    expectedYMotion dist {[-8:0]:=10, [1:7]:=10};
  };

  // Constraints for mismatch index distribution
  constraint mismatchIndexConstraint {
    soft randomMismatchIndex dist {[0:255] := 10, [256:511] := 10, [512:767] := 10}; 
  };

  // Constraints for search memory values
  constraint searchMemoryConstraint {
    foreach(searchMemory[i]) searchMemory[i] inside {[0:`SMEM_MAX-1]};
  };

  // Display function to output transaction details
  function void display();
    $display(" ================================================= [TRANSACTION_INFO] :: Search Memory Generated =================================================");
    for (int j = 0; j < `SMEM_MAX; j++) begin
      if (j % 32 == 0) $display("  ");
      $write("%h  ", searchMemory[j]);
      if (j == 1023) $display("  ");
    end

    $display(" ================================================= [TRANSACTION_INFO] :: Reference Memory Generated =================================================");
    for (int j = 0; j < `RMEM_MAX; j++) begin
      if (j % 16 == 0) $display("  ");
      $write("%h ", referenceMemory[j]);
      if (j == 255) $display("  ");
    end

    $display("\n[TRANSACTION_INFO] :: Random Mismatch Index : %0d", randomMismatchIndex);     
    $display("[TRANSACTION_INFO] :: Expected X Motion : %0d", expectedXMotion);
    $display("[TRANSACTION_INFO] :: Expected Y Motion : %0d", expectedYMotion);
  endfunction

  // Function to generate reference memory based on search memory and motion vectors
  function void generateReferenceMemory();
    foreach (referenceMemory[i]) begin
      // Generate a full match by default
      referenceMemory[i] = searchMemory[32 * 8 + 8 + (((i / 16) + expectedYMotion) * 32) + ((i % 16) + expectedXMotion)];
      
      // Introduce a partial match at the random mismatch index
      if (i == randomMismatchIndex)   
        referenceMemory[i] = $urandom_range(0, 255);
    end

    // Shuffle referenceMemory to create no match if randomMismatchIndex is above a threshold
    if (randomMismatchIndex >= 400) begin
      referenceMemory.shuffle();
    end
  endfunction

endclass

class CoverageAnalysis;
  // Coverage analysis class

  covergroup cg @(posedge clk);
    coverpoint transactionData.bestDistance;
    coverpoint transactionData.expectedXMotion;
    coverpoint transactionData.expectedYMotion;
  endgroup

  function new();
    cg = new();
  endfunction

  task sample(Transaction transactionData);
    cg.sample();
  endtask

endclass

`endif // TRANSACTION_COVERAGE_SV
