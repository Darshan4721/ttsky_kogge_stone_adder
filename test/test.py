# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Serial KSA Test")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    async def shift_in(a, b):
        for i in range(8):
            a_bit = (a >> i) & 1
            b_bit = (b >> i) & 1
            dut._log.info(f"Shift in bit {i}: a={a_bit}, b={b_bit}")
            # ui_in[0] = a_sin, [1] = b_sin, [3] = shift_en
            dut.ui_in.value = (a_bit << 0) | (b_bit << 1) | (1 << 3)
            await ClockCycles(dut.clk, 1)
        dut.ui_in.value = 0

    async def load_and_get_cout(cin):
        # ui_in[2] = cin, [4] = load_en
        dut.ui_in.value = (cin << 2) | (1 << 4)
        await ClockCycles(dut.clk, 1)
        await Timer(1, units="ns")
        cout = int(dut.uo_out.value) & (1 << 1)
        dut.ui_in.value = 0
        return bool(cout)

    async def shift_out():
        sum_val = 0
        for i in range(8):
            await Timer(1, units="ns")
            # uo_out[0] = sum_sout
            bit = int(dut.uo_out.value) & 1
            dut._log.info(f"Read bit {i}: {bit}")
            sum_val |= (int(bit) << i)
            # ui_in[3] = shift_en
            dut.ui_in.value = (1 << 3)
            await ClockCycles(dut.clk, 1)
        dut.ui_in.value = 0
        return sum_val

    # Test Case 1: 20 + 30
    a, b, cin = 20, 30, 0
    expected_sum = (a + b + cin) & 0xFF
    expected_cout = (a + b + cin) >> 8

    dut._log.info(f"Test 1: {a} + {b} + {cin}")
    await shift_in(a, b)
    cout = await load_and_get_cout(cin)
    result_sum = await shift_out()

    dut._log.info(f"Result: Sum={result_sum}, Cout={cout}")
    assert result_sum == expected_sum
    assert cout == expected_cout

    # Test Case 2: 255 + 1
    a, b, cin = 255, 1, 0
    expected_sum = (a + b + cin) & 0xFF
    expected_cout = (a + b + cin) >> 8

    dut._log.info(f"Test 2: {a} + {b} + {cin}")
    await shift_in(a, b)
    cout = await load_and_get_cout(cin)
    result_sum = await shift_out()

    dut._log.info(f"Result: Sum={result_sum}, Cout={cout}")
    assert result_sum == expected_sum
    assert cout == expected_cout

    dut._log.info("All tests passed!")
