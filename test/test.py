import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


async def shift_byte(dut, value, sel):
    # sel = 0 → A, 1 → B
    for i in range(8):
        bit = (value >> i) & 1

        dut.ui_in.value = (bit << 0) | (sel << 1) | (1 << 2)  # load=1
        await ClockCycles(dut.clk, 1)

    # disable load
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 1)


async def read_result(dut):
    result = 0
    for i in range(8):
        await ClockCycles(dut.clk, 1)
        bit = int(dut.uo_out.value) & 1
        result |= (bit << i)
    return result


@cocotb.test()
async def test_project(dut):

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    a = 0
    b = 29

    # Load A
    await shift_byte(dut, a, sel=0)

    # Load B
    await shift_byte(dut, b, sel=1)

    # Start computation
    dut.ui_in.value = (1 << 3)  # start=1
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0

    # Wait 1 cycle (optional)
    await ClockCycles(dut.clk, 1)

    # Read result
    result = await read_result(dut)

    expected = (a + b) & 0xFF

    assert result == expected, f"FAIL: got={result}, expected={expected}"
