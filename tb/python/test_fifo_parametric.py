import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def fifo_parametric_led_test(dut):
    """Cocotb Test: LED Toggle Kontrolü"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    await Timer(50, "ns")
    dut.rst_n.value = 1
    
    for i in range(10):
        await RisingEdge(dut.clk)
        if i % 2 == 0:
            dut._log.info(f"Dongu {i}: LED degeri = {dut.led.value}")
