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
         'en_tick_test',
         'bangen_tick_test',
         'free_run_test_001']

@pytest.mark.parametrize("depth_p,reset_val_p", [(2, 1), (2, 0), (5, 63)])
@pytest.mark.parametrize("test_name", tests)
@pytest.mark.parametrize("simulator", ["verilator", "icarus"])
@max_score(0)
def test_each(test_name, simulator, depth_p, reset_val_p):
    # This line must be first
    parameters = dict(locals())
    del parameters['test_name']
    del parameters['simulator']
    runner(simulator, timescale, tbpath, parameters, testname=test_name)

@pytest.mark.parametrize("depth_p,reset_val_p", [(2, 1), (2, 0), (5, 63)])
@pytest.mark.parametrize("simulator", ["verilator", "icarus"])
@max_score(3)
def test_all_runner(simulator, depth_p, reset_val_p):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    runner(simulator, timescale, tbpath, parameters)

@pytest.mark.parametrize("depth_p,reset_val_p", [(5, 63)])
@pytest.mark.parametrize("simulator", ["verilator"])
@max_score(.4)
def test_lint(simulator, depth_p, reset_val_p):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    lint(simulator, timescale, tbpath, parameters)

@pytest.mark.parametrize("depth_p,reset_val_p", [(5, 63)])
@pytest.mark.parametrize("simulator", ["verilator"])
@max_score(.1)
def test_style(simulator, depth_p, reset_val_p):
    # This line must be first
    parameters = dict(locals())
    del parameters['simulator']
    lint(simulator, timescale, tbpath, parameters, compile_args=["--lint-only", "-Wwarn-style", "-Wno-lint"])

### Begin Tests ###
    

@cocotb.test()
async def reset_test(dut):
    """Test for Initialization"""

    clk_i = dut.clk_i
    reset_i = dut.reset_i
    enable_i = dut.enable_i
    data_i = dut.data_i
    data_o = dut.data_o

    enable_i.value = LogicArray(['x'])
    data_i.value = LogicArray(['x'])

    await clock_start_sequence(clk_i)
    await reset_sequence(clk_i, reset_i, 10)

    assert data_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert data_o.value == dut.reset_val_p.value, f"Incorrect Result: data_o should be {dut.reset_val_p.value} after reset. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."

async def wait_for(clk_i, signal, value):
    while(signal.value.is_resolvable and signal.value != value):
        await FallingEdge(clk_i)

@cocotb.test()
async def en_tick_test(dut):
    """Test one clock cycle of the shift register"""

    clk_i = dut.clk_i
    reset_i = dut.reset_i
    enable_i = dut.enable_i
    data_i = dut.data_i
    data_o = dut.data_o

    enable_i.value = LogicArray(['x'])
    data_i.value = LogicArray(['x'])

    await clock_start_sequence(clk_i)
    await reset_sequence(clk_i, reset_i, 10)

    # First, test shifting in a 1
    data_i.value = 1
    enable_i.value = 1

    await FallingEdge(dut.clk_i)

    expected = ((dut.reset_val_p.value << 1) | dut.data_i.value) & ((1 << dut.depth_p.value) - 1)

    assert data_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert data_o.value == expected, f"Incorrect Result: data_o != {expected}. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."

    await RisingEdge(dut.clk_i)

    # Then do the same test, but shift in a 0

    await reset_sequence(clk_i, reset_i, 10)

    data_i.value = 0
    enable_i.value = 1

    await FallingEdge(dut.clk_i)

    expected = ((dut.reset_val_p.value << 1) | dut.data_i.value) & ((1 << dut.depth_p.value) - 1)

    assert data_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert data_o.value == expected, f"Incorrect Result: data_o != {expected}. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."


@cocotb.test()
async def bangen_tick_test(dut):
    """Test one clock cycle of the shift register, with enable low"""

    clk_i = dut.clk_i
    reset_i = dut.reset_i
    enable_i = dut.enable_i
    data_i = dut.data_i
    data_o = dut.data_o

    enable_i.value = LogicArray(['x'])
    data_i.value = LogicArray(['x'])

    await clock_start_sequence(clk_i)
    await reset_sequence(clk_i, reset_i, 10)

    # First, test shifting in a 1, but no enable
    data_i.value = 1
    enable_i.value = 0

    await FallingEdge(dut.clk_i)

    # Shouldn't change
    expected = dut.reset_val_p.value

    assert data_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert data_o.value == expected, f"Incorrect Result: data_o != {expected}. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."

    await RisingEdge(dut.clk_i)

    # Then do the same test, but "shift" in a 0

    await reset_sequence(clk_i, reset_i, 10)

    data_i.value = 0
    enable_i.value = 0

    await FallingEdge(dut.clk_i)

    # Shouldn't change
    expected = dut.reset_val_p.value

    assert data_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
    assert data_o.value == expected, f"Incorrect Result: data_o != {expected}. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."



async def free_run_test(dut, l):
    """Test 100 cycles of the shift register"""

    clk_i = dut.clk_i
    reset_i = dut.reset_i
    enable_i = dut.enable_i
    data_i = dut.data_i
    data_o = dut.data_o

    enable_i.value = LogicArray(['x'])
    data_i.value = LogicArray(['x'])

    await clock_start_sequence(clk_i)
    await reset_sequence(clk_i, reset_i, 10)

    data_i.value = 0
    enable_i.value = 0
    await FallingEdge(clk_i)

    expected = dut.reset_val_p.value
    mask = (1 << dut.depth_p.value) -1

    seq = [random.randint(0, 4) for i in range(l)]
    for i in seq:
        assert data_o.value.is_resolvable, f"Unresolvable value (x or z in some or all bits) at Time {get_sim_time(units='ns')}ns."
        assert data_o.value == expected, f"Incorrect Result: data_o != {expected}. Got: {data_o.value} at Time {get_sim_time(units='ns')}ns."

        enable_i.value = (i == 1 or i == 3)
        data_i.value = (i == 2 or i == 3)
        await FallingEdge(dut.clk_i)
        if(enable_i.value):
            expected = ((expected << 1) | data_i.value) & mask
           
tf = TestFactory(test_function=free_run_test)
tf.add_option(name='l', optionlist=[100])
tf.generate_tests()

