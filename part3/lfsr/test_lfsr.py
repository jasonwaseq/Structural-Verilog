import git
import os
import sys
import git

# I don't like this, but it's convenient.
_REPO_ROOT = git.Repo(search_parent_directories=True).working_tree_dir
assert (os.path.exists(_REPO_ROOT)), "REPO_ROOT path must exist"
sys.path.append(os.path.join(_REPO_ROOT, "util"))
from utilities import runner, lint, assert_resolvable, clock_start_sequence, reset_sequence
tbpath = os.path.dirname(os.path.realpath(__file__))

import pytest

import cocotb

from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, with_timeout
from cocotb.types import LogicArray, Range

from cocotb_test.simulator import run

from cocotbext.axi import AxiLiteBus, AxiLiteMaster, AxiStreamSink, AxiStreamMonitor, AxiStreamBus

from pytest_utils.decorators import max_score, visibility, tags
   
import random
random.seed(42)

timescale = "1ps/1ps"
      
tests = ['reset_test',
         'tick_test',
         'loop_test'
         ]

@pytest.mark.parametrize("test_name", tests)
@pytest.mark.parametrize("simulator", ["verilator", "icarus"])
@max_score(0)
def test_each(test_name, simulator):
    # This line must be first
    parameters = dict(locals())
    del parameters['test_name']
    del parameters['simulator']
    runner(simulator, timescale, tbpath, parameters, testname=test_name)

# Opposite above, run all the tests in one simulation but reset
# between tests to ensure that reset is clearing all state.
@pytest.mark.parametrize("simulator", ["verilator", "icarus"])
@max_score(3)
def test_all(simulator):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    runner(simulator, timescale, tbpath, parameters)

@pytest.mark.parametrize("simulator", ["verilator"])
@max_score(.4)
def test_lint(simulator):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    lint(simulator, timescale, tbpath, parameters)

@pytest.mark.parametrize("simulator", ["verilator"])
@max_score(.1)
def test_style(simulator):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    lint(simulator, timescale, tbpath, parameters, compile_args=["--lint-only", "-Wwarn-style", "-Wno-lint"])


### Begin Tests ###
    
@cocotb.test()
async def reset_test(dut):
    """Test for Initialization"""

    reset_i = dut.reset_i
    data_o = dut.data_o
    en_i = dut.en_i
    clk_i = dut.clk_i

    await clock_start_sequence(clk_i)
    model = LfsrModel(clk_i, reset_i, en_i, data_o)
    model.start()

    await reset_sequence(clk_i, reset_i, 10)

    # Always check outputs on the rising edge
    await RisingEdge(clk_i)

    assert_resolvable(data_o)
    expected = model._state
    assert data_o.value == expected, f"Incorrect Result: data_o != {expected}. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."

async def wait_for(clk_i, signal, value):
    while(signal.value.is_resolvable and signal.value != value):
        await FallingEdge(clk_i)

@cocotb.test()
async def tick_test(dut):
    """Test one clock cycle of the LFSR"""

    reset_i = dut.reset_i
    data_o = dut.data_o
    en_i = dut.en_i
    clk_i = dut.clk_i

    await clock_start_sequence(clk_i)
    model = LfsrModel(clk_i, reset_i, en_i, data_o)
    model.start()

    en_i.value = 0

    await reset_sequence(clk_i, reset_i, 10)

    en_i.value = 1

    await RisingEdge(clk_i)

    expected = model._state
    assert_resolvable(data_o)
    assert data_o.value == expected, f"Incorrect Result: data_o != {expected}. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."

@cocotb.test()
async def loop_test(dut):
    """Test two complete cycles of the LFSR"""

    reset_i = dut.reset_i
    data_o = dut.data_o
    en_i = dut.en_i
    clk_i = dut.clk_i

    await clock_start_sequence(clk_i)
    model = LfsrModel(clk_i, reset_i, en_i, data_o)
    model.start()

    en_i.value = 0

    await reset_sequence(clk_i, reset_i, 10)
    en_i.value = 1

    for i in range(6 * (2<<(len(data_o))-1)):
        await RisingEdge(clk_i)
        expected = model._state
        assert_resolvable(data_o)
        assert data_o.value == expected, f"Incorrect Result: data_o != {expected}. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."
        await FallingEdge(clk_i)
        en_i.value = ((i % 3) == 1)
        
class LfsrModel():
    def __init__(self, clk_i, reset_i, en_i, data_o):
        self._clk_i = clk_i
        self._reset_i = reset_i
        self._en_i = en_i
        self._data_o = data_o
        self._state = 0
        self._nstate = 0
        self._coro_run = None

    def start(self):
        """Start model"""
        if self._coro_run is not None:
            raise RuntimeError("Model already started")
        self._coro_run = cocotb.start_soon(self._run())

    async def _run(self):
        while True:
            await RisingEdge(self._clk_i)
            if(not(self._reset_i.value.is_resolvable)):
                pass
            elif(self._reset_i.value == 1):
                self._nstate = 1
            elif(self._en_i.value.is_resolvable and self._en_i.value == 0):
                pass
            elif(self._en_i.value.is_resolvable and self._en_i.value == 1):
                self._nstate = (self._nstate << 1) | (((self._nstate>>1)&1) ^ ((self._nstate>>10)&1))

            self._nstate = self._nstate & ((1<< 11) - 1)
            await FallingEdge(self._clk_i)
            self._state = self._nstate 
      
    def stop(self) -> None:
        """Stop monitor"""
        if self._coro_run is None:
            raise RuntimeError("Monitor never started")
    
