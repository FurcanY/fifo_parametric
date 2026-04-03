# --- Derleyici ve Arac Tanimlamalari --- #
VERILATOR := verilator
GTKWAVE   := gtkwave

# --- Dosya Yollari --- #
RTL_SRC     := ./src/rtl/fifo_parametric.sv
PKG_SRC     := $(wildcard ./src/pkg/*.sv)
TB_SRC      := ./tb/fifo_parametric_tb.sv
VCD_DIR     := ./sim/vcd
VCD_FILE    := $(VCD_DIR)/trace.vcd
LOG_DIR     := ./sim/logs

# --- Verilator Bayraklari --- #
V_FLAGS := -Wall --trace --assert --timing \
	       -Wno-CASEINCOMPLETE -Wno-MULTIDRIVEN -Wno-UNUSEDSIGNAL -Wno-TIMESCALEMOD \
	       --top-module fifo_parametric_tb \
		   -DFIFO_PARAMETRIC_DEBUG \

# --------------------------------------------------
#  HEDEFLER (TARGETS)
# --------------------------------------------------

.PHONY: all lint build run wave clean cocotb

all: run

# 1. LINT
lint:
	$(VERILATOR) --lint-only $(V_FLAGS) $(PKG_SRC) $(RTL_SRC) $(TB_SRC)

# 2. BUILD
build: lint
	@mkdir -p $(VCD_DIR) $(LOG_DIR)
	$(VERILATOR) --binary $(V_FLAGS) \
	    -j 0 \
	    $(PKG_SRC) $(RTL_SRC) $(TB_SRC) \
	    --Mdir obj_dir_fifo_parametric

# 3. RUN (Terminal + Log)
run: build
	@echo "🏃 Simülasyon basliyor..."
	./obj_dir_fifo_parametric/Vfifo_parametric_tb +trace | tee $(LOG_DIR)/sim.log

# 4. WAVE
wave:
	@if [ -f $(VCD_FILE) ]; then $(GTKWAVE) $(VCD_FILE); else echo "❌ VCD bulunamadi!"; fi

# 5. COCOTB
cocotb:
	@mkdir -p $(LOG_DIR)
	rm -rf sim_build
	$(MAKE) -f ./scripts/Makefile.cocotb > $(LOG_DIR)/cocotb.log 2>&1
	@echo "📝 Cocotb loglari $(LOG_DIR)/cocotb.log icine kaydedildi."

# 6. CLEAN
clean:
	rm -rf obj_dir_fifo_parametric sim_build $(VCD_DIR) $(LOG_DIR) results.xml
