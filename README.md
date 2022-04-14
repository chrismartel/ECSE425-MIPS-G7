# ECSE425-MIPS-G7
VHDL implementation of a simplified 5-stage MIPS Processor with integrated forwarding and data hazard detection.

## **Components**

* **Fetch**
The VHDL source code for the fetch component implementation is available here: [fetch.vhd](src/mips/fetch/fetch.vhd).
* **Register File**
* The VHDL source code for the register file component implementation is available here: [regs.vhd](src/mips/regster_file/regs.vhd).
* **Decode**
* The VHDL source code for the decode component implementation is available here: [decode.vhd](src/mips/decode/decode.vhd).
* **Execute**
* The VHDL source code for the execute component implementation is available here: [execute.vhd](src/mips/ex/execute.vhd).
* **Memory**
* The VHDL source code for the memory component implementation is available here: [memory.vhd](src/mips/memory_access/memory.vhd).
* **Write-Back**
* The VHDL source code for the write-back component implementation is available here: [writeback.vhd](src/mips/writeback/writeback.vhd).
* **Forwarding Unit**
* The VHDL source code for the forwarding unit component implementation is available here: [forwarding_unit.vhd](src/mips/forwarding/forwarding_unit.vhd).

## **Testbenches**

* **Fetch**
The VHDL source code for the fetch component test bench implementation is available here: [fetch_tb.vhd](src/mips/fetch/fetch_tb.vhd).  
The TCL script to run the fetch test bench is available here: [fetch_tb.tcl](src/mips/fetch/fetch_tb.tcl).
* **Decode**
The VHDL source code for the fetch component test bench implementation is available here: [fetch_tb.vhd](src/mips/fetch/fetch_tb.vhd).
The TCL script to run the fetch test bench is available here: [fetch_tb.tcl](src/mips/fetch/fetch_tb.tcl).
* **Execute**
The VHDL source code for the execute component test bench implementation is available here: [execute_tb.vhd](src/mips/ex/execute_tb.vhd).
The TCL script to run the execute test bench is available here: [execute_tb.tcl](src/mips/ex/execute_tb.tcl).
* **Memory**
The VHDL source code for the fetch component test bench implementation is available here: [fetch_tb.vhd](src/mips/fetch/fetch_tb.vhd).
The TCL script to run the fetch test bench is available here: [fetch_tb.tcl](src/mips/fetch/fetch_tb.tcl).
* **Write-Back**
The VHDL source code for the fetch component test bench implementation is available here: [fetch_tb.vhd](src/mips/fetch/fetch_tb.vhd).
The TCL script to run the fetch test bench is available here: [fetch_tb.tcl](src/mips/fetch/fetch_tb.tcl).
