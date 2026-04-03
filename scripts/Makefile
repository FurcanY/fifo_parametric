# Simülatör ayarları
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

# Proje Kök Dizini (scripts içinde olduğumuz için bir üst dizin)
PROJ_ROOT = $(shell pwd)/..

# --- Kaynak Dosyalar (Yollar Kök Dizine Göre) ---
VERILOG_SOURCES += $(PROJ_ROOT)/src/pkg/fifo_parametric_pkg.sv
VERILOG_SOURCES += $(PROJ_ROOT)/src/rtl/fifo_parametric.sv

# --- Üst Modül ve Test Ayarları ---
TOPLEVEL = fifo_parametric
MODULE   = test_fifo_parametric

# --- Python Test Yolunu Tanımlama ---
# Cocotb'un .py dosyasını bulması için PYTHONPATH'e ekliyoruz
export PYTHONPATH := $(PROJ_ROOT)/tb/python:$(PYTHONPATH)

# Verilator için dalga formu ve yapı desteği
EXTRA_ARGS += --trace --trace-structs

include $(shell cocotb-config --makefiles)/Makefile.sim