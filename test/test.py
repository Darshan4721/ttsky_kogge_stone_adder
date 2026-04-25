import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge

@cocotb.test()
async def test_project(dut):
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    test_vectors = [(15, 10, 0), (200, 100, 0)]

    for a, b, cin in test_vectors:
        # Cycle 0: S_LOAD_A (Drive inputs while clock is low)
        await FallingEdge(dut.clk)
        dut.ui_in.value = a
        dut.uio_in.value = cin
        
        # Cycle 1: S_LOAD_B
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = b
        
        # Cycle 2: Wait for S_OUT_SUM (Adder computes during this cycle)
        await ClockCycles(dut.clk, 1)
        
        # Cycle 3: Wait for S_OUT_CARRY
        await ClockCycles(dut.clk, 1)
        
        # Sample outputs
        # Note: Depending on your FSM, you might need to read 
        # result sequentially over two cycles if the port is shared.
        await FallingEdge(dut.clk)
        sum_val = int(dut.uo_out.value)
        
        await ClockCycles(dut.clk, 1)
        await FallingEdge(dut.clk)
        cout_val = int(dut.uo_out.value)

        expected_total = a + b + cin
        assert sum_val == (expected_total & 0xFF), f"Sum fail: got {sum_val}, exp {expected_total & 0xFF}"
        assert cout_val == ((expected_total >> 8) & 1), f"Cout fail: got {cout_val}"

    dut._log.info("Test Passed!")
