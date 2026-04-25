# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


# -------------------------------
# Shift 8-bit value serially
# -------------------------------
async def shift_byte(dut, value, sel):
    # sel = 0 → A, 1 → B

    for i in range(8):
        # MSB-first (IMPORTANT FIX)
        bit = (value >> (7 - i)) & 1

        # ui_in mapping:
        # bit0 = serial_in
        # bit1 = sel_ab
        # bit2 = load
        dut.ui_in.value = (bit << 0) | (sel << 1) | (1 << 2)

        await ClockCycles(dut.clk, 1)

    # Disable load
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 1)


# -------------------------------
# Read 8-bit result serially
# -------------------------------
async def read_result(dut):
    result = 0

    for i in range(8):
        await ClockCycles(dut.clk, 1)

        val = dut.uo_out[0].value

        # Safe read (avoid X crash)
        if not val.is_resolvable:
            raise Exception("X detected on output")

        bit = int(val)
        result |= (bit << i)

    return result


# -------------------------------
# Main Test
# -------------------------------
@cocotb.test()
async def test_project(dut):

    dut._log.info("Start Serial Kogge-Stone Test")

    # Clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # Test values
    a = 0
    b = 29

    dut._log.info(f"Loading A={a}, B={b}")

    # Load A
    await shift_byte(dut, a, sel=0)

    # Load B
    await shift_byte(dut, b, sel=1)

    # Start computation
    dut._log.info("Starting computation")
    dut.ui_in.value = (1 << 3)  # start = 1
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0

    # Wait for result to latch (IMPORTANT)
    await ClockCycles(dut.clk, 2)

    # Read result serially
    result = await read_result(dut)

    expected = (a + b) & 0xFF

    dut._log.info(f"Result={result}, Expected={expected}")

    assert result == expected, f"FAIL: got={result}, expected={expected}"
