UKP = $(HOME)/Software/ukrmolp-git

FC      = gfortran
FFLAGS  = -std=f2018 -fdefault-integer-8
INCLUDE = -I$(UKP)/include/cdenprop -I$(UKP)/include/utilities
LIBS    = -L$(UKP)/lib64 -lcdenprop -lukplus_utilities
LDFLAGS = -Wl,-rpath,$(UKP)/lib64

all: polarizability

clean:
	rm -f polarizability polarizability.o

polarizability: polarizability.o
	$(FC) $^ -o $@ $(LDFLAGS) $(LIBS)

polarizability.o: polarizability.f90
	$(FC) $< -c -o $@ $(FFLAGS) $(INCLUDE)

