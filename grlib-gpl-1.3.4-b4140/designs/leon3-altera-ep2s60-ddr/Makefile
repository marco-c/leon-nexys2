GRLIB=../..
TOP=leon3mp
BOARD=altera-ep2s60-ddr
include $(GRLIB)/boards/$(BOARD)/Makefile.inc
DEVICE=$(PART)-$(PACKAGE)$(SPEED)
UCF=$(GRLIB)/boards/$(BOARD)/$(TOP).ucf
QSF=$(GRLIB)/boards/$(BOARD)/$(TOP).qsf
EFFORT=std
XSTOPT=
SYNPOPT="set_option -pipe 1; set_option -retiming 1; set_option -verification_mode 1; set_option -write_apr_constraint 0"
VHDLSYNFILES=config.vhd ahbrom.vhd smc_mctrl.vhd leon3mp.vhd 
VHDLSIMFILES=testbench.vhd
SIMTOP=testbench
SDCFILE=$(GRLIB)/boards/$(BOARD)/default.sdc
BITGEN=$(GRLIB)/boards/$(BOARD)/default.ut
CLEAN=soft-clean

TECHLIBS = altera altera_mf stratixii
LIBSKIP = gsi spansion fmf core1553bbc core1553brm core1553brt gr1553 corePCIF \
	tmtc openchip ihp usbhc spw eth hynix
DIRSKIP = b1553 pci/pcif leon2 leon2ft crypto satcan pci leon3ft ambatest can \
	grusbhc spacewire usb greth net hcan leon4 leon4v0
FILESKIP = grcan.vhd

include $(GRLIB)/software/leon3/Makefile
include $(GRLIB)/bin/Makefile


##################  project specific targets ##########################

