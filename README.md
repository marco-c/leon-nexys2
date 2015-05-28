# leon-nexys2
LEON on the Digilent Nexys 2 board

To configure LEON:
```bash
cd grlib-gpl-1.3.4-b4140/designs/leon3-digilent-nexys2
make xconfig
```


To build LEON:
```bash
export PATH=$PATH:/path/to/ISE/binaries # Usually something like /opt/Xilinx/14.1/ISE_DS/ISE/bin/lin64
cd grlib-gpl-1.3.4-b4140/designs/leon3-digilent-nexys2
make ise # Build from the command line
make ise-launch # Build using the ISE GUI
```
