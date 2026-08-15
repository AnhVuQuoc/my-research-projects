IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave

MKPATH   := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT     := $(patsubst %/scripts/common.mk,%,$(MKPATH))

BUILD    ?= sim
RTL      ?= $(wildcard rtl/*.v)
TBDIRS   ?= tb tb/agent tb/tests

EXTRA_INCDIRS ?=
INCDIRS  := -I$(ROOT)/common -Irtl $(addprefix -I,$(TBDIRS)) \
            $(addprefix -I,$(EXTRA_INCDIRS))


IVFLAGS  ?= -g2005 -Wall -Wno-timescale

DUMP     ?= 0
ifeq ($(DUMP),1)
  IVFLAGS += -DDUMP_VCD
endif

TBLIB    ?= $(wildcard tb/agent/*.v)

.PHONY: all lint clean waves help $(TESTS)

all: $(TESTS)
	@echo ""
	@echo "###########################################################"
	@echo "#  $(PROJ) : all tests completed"
	@echo "###########################################################"

$(TESTS): %: | $(BUILD)
	@echo ""
	@echo ">>> [$(PROJ)] compiling $@"
	@$(IVERILOG) $(IVFLAGS) $(INCDIRS) -o $(BUILD)/$@.vvp \
		$(RTL) $(TBLIB) $(TB_$@) $(wildcard tb/$@.v) $(wildcard tb/tests/$@.v)
	@echo ">>> [$(PROJ)] running   $@"
	@cd $(BUILD) && $(VVP) $@.vvp $(PLUSARGS) 2>&1 | tee $@.log
	@if grep -q "FAILED" $(BUILD)/$@.log; then \
		echo "!!! $@ : FAILED"; exit 1; \
	elif grep -q "PASSED" $(BUILD)/$@.log; then \
		echo "+++ $@ : PASSED"; \
	else \
		echo "!!! $@ : NO RESULT LINE (test did not finish)"; exit 1; \
	fi

$(BUILD):
	@mkdir -p $(BUILD)

lint:
	@for t in $(TESTS); do \
		echo ">>> lint $$t"; \
		$(IVERILOG) $(IVFLAGS) $(INCDIRS) -o /dev/null \
			$(RTL) $(TBLIB) tb/$$t.v tb/tests/$$t.v 2>/dev/null || \
		$(IVERILOG) $(IVFLAGS) $(INCDIRS) -o /dev/null \
			$(RTL) $(TBLIB) tb/$$t.v ; \
	done

waves:
	@test -n "$(TEST)" || (echo "usage: make waves TEST=tb_name"; exit 1)
	$(GTKWAVE) $(BUILD)/$(TEST).vcd &

clean:
	rm -rf $(BUILD)

help:
	@echo "$(PROJ) tests: $(TESTS)"
