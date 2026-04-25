# SPDX-FileCopyrightText: © 2024 Your Name
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start 4-Cycle Kogge-Stone Adder Test")

    # 1. Initialize Clock (10 MHz / 100ns period)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # 2. Reset Sequence
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    dut._log.info("Applying reset...")
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    
    # Wait one cycle to ensure we are aligned with the S_LOAD_A state
    await ClockCycles(dut.clk, 1)

    # 3. Define Test Vectors: (A, B, Cin)
    test_vectors = [
        (15, 10, 0),      # Standard addition (no overflow)
        (200, 100, 0),    # Addition with carry out
        (0, 0, 0),        # Zero test
        (255, 0, 1),      # Cin ripple test
        (255, 255, 1)     # Max values
    ]

    # 4. Run Test Cases
    for a, b, cin in test_vectors:
        dut._log.info(f"Testing A={a}, B={b}, Cin={cin}")

        # --- Cycle 0: S_LOAD_A ---
        # Drive A on ui_in, and Cin on uio_in[0]
        dut.ui_in.value = a
        dut.uio_in.value = cin
        await ClockCycles(dut.clk, 1)

        # --- Cycle 1: S_LOAD_B ---
        # Drive B on ui_in
        dut.ui_in.value = b
        await ClockCycles(dut.clk, 1)

        # --- Cycle 2: S_OUT_SUM ---
        # The FSM is now outputting the sum. We wait for the falling edge 
        # to safely sample the value in the middle of the clock cycle.
        await FallingEdge(dut.clk)
        
        # Read the Sum
        sum_val = int(dut.uo_out.value)
        
        # Move to the next clock edge
        await ClockCycles(dut.clk, 1) 

        # --- Cycle 3: S_OUT_CARRY ---
        await FallingEdge(dut.clk)
        
        # Read the Carry Out
        cout_val = int(dut.uo_out.value)

        # Calculate Expected Results
        expected_total = a + b + cin
        expected_sum = expected_total & 0xFF       # Bottom 8 bits
        expected_cout = (expected_total >> 8) & 1  # 9th bit

        dut._log.info(f"Result: Sum={sum_val} (Exp: {expected_sum}), Cout={cout_val} (Exp: {expected_cout})")

        # Assertions to fail the test if there is a mismatch
        assert sum_val == expected_sum, f"FAIL: A={a}, B={b}. Sum got {sum_val}, expected {expected_sum}"
        assert cout_val == expected_cout, f"FAIL: A={a}, B={b}. Cout got {cout_val}, expected {expected_cout}"
        
        # Move to the next rising edge so the loop perfectly aligns with S_LOAD_A again
        await ClockCycles(dut.clk, 1) 
        
    dut._log.info("All tests passed!")
