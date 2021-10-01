BASE = $(CCSL)
SRC = $(BASE)/source
LIB = $(BASE)/lib
EXE = $(BASE)/exe
GRAF = $(BASE)/graf
OPT = $(CCSL_OPT)
PERLD= $(BASE)/perl
DOCCSL = perl $(PERLD)/ccsl
DOCCSLD = perl -d $(PERLD)/make_ccsl
CCSLOPT= lax unix ill
CC = gfortran
CFLAGS = -m64 -Wall
3LFLAGS = -arch i386
PIGLET = pignup
GLIBS = /usr/local/lib/libpgplot.a  -L/usr/X11R6/lib -lX11 -lpng -L/usr/lib -lz

all: $(LIB)/libmk4.a   progs.stamp
main:  $(SRC)/maimk4.f progs.stamp

lib: $(SRC)/libmk4.f $(SRC)/pigmk4.f

LIBA: $(LIB)/libmk4.a


mai: $(SRC)/maimk4.f

progs: $(OPT)/progs.stamp

progs.stamp : $(LIB)/libmk4.a  $(SRC)/maimk4.f \
            $(OPT)/list_of_progs
	$(DOCCSL) -l mai
	touch progs.stamp;

$(LIB)/libmk4.a : $(SRC)/libmk4.f $(SRC)/pigmk4.f
	rm -f $(BASE)/fortran.errors
	$(DOCCSL) -a lib
	 ranlib $(LIB)/libmk4.a

$(SRC)/libmk4.f : $(SRC)/mistre.ss
	$(DOCCSL) -e lib

$(SRC)/pigmk4.f : $(SRC)/mistre.ss
	 $(DOCCSL) -e pig

$(SRC)/maimk4.f : $(SRC)/mistre.ss
	 $(DOCCSL) -e mai


.PHONY: pclean
pclean:
	$(DOPATCH) -c $(CCSL)
	rm -rf $(BASE)/patch

.PHONY: cleanup
cleanup:
ifneq "$(strip $(BASE))" ""
	rm  -f $(BASE)/fortran.errors
	rm -rf $(BASE)/bad $(BASE)/tempdir
else
		echo  "BASE variable missing"
endif

.PHONY: clean
clean:
ifneq ($(strip $(EXE)),)
#	rm -rf  $(EXE)
else
	echo  "EXE variable missing"
endif
ifneq ($(strip $(GRAF)),)
#	rm -rf $(GRAF)/*
else
	echo  "GRAF variable missing"
endif
ifneq ($(strip $(LIB)),)
#	rm -f $(LIB)/*.a
else
	echo  "LIB variable missing"
endif
ifneq ($(strip $(SRC)),)
#	rm -f $(SRC)/*.f
else
	echo  "SRC variable missing"
endif
ifneq ($(strip $(OPT)),)
	echo  " $(OPT) defined OK"
#	rm -f $(OPT)/progs.stamp
else
	echo  "SRC variable missing"
endif
