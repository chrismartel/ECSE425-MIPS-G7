# ECSE425-MIPS-G7
VHDL implementation of a simplified 5-stage MIPS Processor with integrated forwarding and data hazard detection.

## **Implementation**

### **MIPS Pipelined Processor**
The VHDL source file for the pipelined processor is available here: [mips.vhd](src/mips/mips/mips.vhd)

### **Components**
* **Fetch**  
The VHDL source code for the fetch stage component implementation is available here: [fetch.vhd](src/mips/fetch/fetch.vhd).
* **Register File**  
The VHDL source code for the register file component implementation is available here: [regs.vhd](src/mips/register_file/regs.vhd).
* **Decode**  
The VHDL source code for the decode stage component implementation is available here: [decode.vhd](src/mips/decode/decode.vhd).
* **Execute**  
The VHDL source code for the execute stage component implementation is available here: [execute.vhd](src/mips/ex/execute.vhd).
* **Memory**  
The VHDL source code for the memory stage component implementation is available here: [memory.vhd](src/mips/memory_access/memory.vhd).
* **Write-Back**  
The VHDL source code for the write-back stage component implementation is available here: [write_back.vhd](src/mips/writeback/write_back.vhd).
* **Forwarding Unit**  
The VHDL source code for the forwarding unit component implementation is available here: [forwarding_unit.vhd](src/mips/forwarding/forwarding_unit.vhd).  

### **Memory**  
* **Instruction Memory**  
The VHDL source code for the instruction memory component implementation is available here: [instruction_memory.vhd](src/mips/memory/instruction_memory.vhd).
* **Data Memory**  
The VHDL source code for the data memory component implementation is available here: [data_memory.vhd](src/mips/memory/data_memory.vhd).

## **Testing**  
The TCL scipts can be run in ModelSIM with the following command: _source <name_of_script>.tcl_
* **Fetch**  
The VHDL source code for the fetch stage component test bench implementation is available here: [fetch_tb.vhd](src/mips/fetch/fetch_tb.vhd).  
The TCL script to run the fetch stage test bench is available here: [fetch_tb.tcl](src/mips/fetch/fetch_tb.tcl).
* **Execute**  
The VHDL source code for the execute stage component test bench implementation is available here: [execute_tb.vhd](src/mips/ex/execute_tb.vhd).  
The TCL script to run the execute stage test bench is available here: [execute_tb.tcl](src/mips/ex/execute_tb.tcl).
* **Decode + Execute**  
The VHDL source code for the integrated register file, decode stage, execute stage, and forwarding unit test bench implementation is available here: [id_ex_tb.vhd](src/mips/mips/id_ex_tb.vhd).  
The TCL script to run the test bench s available here: [id_ex_tb.tcl](src/mips/mips/id_ex_tb.tcl).  
* **Memory**  
The VHDL source code for the memory stage component test bench implementation is available here: [memory_tb.vhd](src/mips/memory_access/memory_tb.vhd).  
The TCL script to run the memory stage test bench is available here: [memorytest.tcl](src/mips/memory_access/memorytest.tcl).
* **Write-Back**  
The VHDL source code for the writeback stage component test bench implementation is available here: [write_back_tb.vhd](src/mips/writeback/write_back_tb.vhd).  
The TCL script to run the writeback stage test bench is available here: [write_back_tb.tcl](src/mips/writeback/write_back_tb.tcl).

### **Memory**  
* **Data & Instruction Memory**  
The VHDL source code for the instruction memory test bench implementation is available here: [instruction_memory_tb.vhd](src/mips/memory/instruction_memory_tb.vhd).  
The TCL script to run the instruction memory test bench is available here: [instruction_memory_tb.tcl](src/mips/memory/instruction_memory_tb.tcl).
