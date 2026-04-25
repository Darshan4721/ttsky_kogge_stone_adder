@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    dut._log.info("Testing Kogge-Stone Adder")

    # Test multiple values
    for a in range(0, 256, 17):
        for b in range(0, 256, 29):

            dut.ui_in.value = a
            dut.uio_in.value = b

            await ClockCycles(dut.clk, 1)

            expected = (a + b) & 0xFF
            result = dut.uo_out.value.integer

            assert result == expected, \
                f"FAIL: a={a}, b={b}, got={result}, expected={expected}"
