// =============================================================================
// File        : tb/uvm/timer_adc_ral.sv   register model (16 registers) + adapter
// Author      : Vu Quoc Anh (SE203519)
// =============================================================================
class tadc_reg extends uvm_reg;
    uvm_reg_field f;
    `uvm_object_utils(tadc_reg)
    function new(string name = "tadc_reg"); super.new(name, 8, UVM_NO_COVERAGE); endfunction
    function void setup(string acc, bit [7:0] rst, bit vol);
        f = uvm_reg_field::type_id::create("f");
        f.configure(this, 8, 0, acc, vol, rst, 1, 0, 1);
    endfunction
endclass

class timer_adc_reg_block extends uvm_reg_block;
    `uvm_object_utils(timer_adc_reg_block)
    tadc_reg regs [16];
    static string NAMES [16] = '{"TMR_CTRL", "TMR_PRESC", "TMR_LOAD", "TMR_CMP", "TMR_CNT", "ADC_CTRL", "ADC_SMP", "ADC_DIV",
                                "ADC_THR_LO", "ADC_THR_HI", "ADC_DATA", "ADC_RCH", "ADC_STAT", "IRQ_EN", "IRQ_STAT", "ID"};
    static bit [7:0] RESET [16] = '{8'h00, 8'h00, 8'hFF, 8'h80, 8'h00, 8'h00, 8'h04, 8'h00, 8'h00, 8'hFF, 8'h00, 8'h00, 8'h10, 8'h00, 8'h00, 8'hA8};
    static bit       IS_RW [16] = '{1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0};
    function new(string name = "timer_adc_reg_block"); super.new(name, UVM_NO_COVERAGE); endfunction
    virtual function void build();
        default_map = create_map("map", 0, 1, UVM_LITTLE_ENDIAN);
        foreach (regs[i]) begin
            regs[i] = tadc_reg::type_id::create(NAMES[i]);
            regs[i].configure(this, null, "");
            regs[i].setup(IS_RW[i] ? "RW" : (i == 14 ? "W1C" : "RO"), RESET[i], !IS_RW[i] || i == 0 || i == 5);
            default_map.add_reg(regs[i], i, IS_RW[i] ? "RW" : (i == 14 ? "RW" : "RO"));
        end
        lock_model();
    endfunction
endclass

class apb_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(apb_reg_adapter)
    function new(string name = "apb_reg_adapter"); super.new(name); supports_byte_enable = 0; provides_responses = 0; endfunction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        apb_item t = apb_item::type_id::create("t");
        t.write = (rw.kind == UVM_WRITE); t.addr = rw.addr[3:0]; t.data = rw.data[7:0];
        return t;
    endfunction
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        apb_item t;
        if (!$cast(t, bus_item)) `uvm_fatal("ADAPT", "not an apb_item")
        rw.kind = t.write ? UVM_WRITE : UVM_READ; rw.addr = t.addr; rw.data = t.data; rw.status = UVM_IS_OK;
    endfunction
endclass
