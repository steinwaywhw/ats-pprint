
AR=ar -rcs
PATSOPT=patsopt -IATS node_modules
CC=gcc -DATS_MEMALLOC_LIBC -I$(PATSHOME) -I$(PATSHOME)/ccomp/runtime 
CCFLAGS=-fPIC -O2
PATSCC=patscc -DATS_MEMALLOC_LIBC -IIATS node_modules -L node_modules/ats-utils -latsutils 
RMF=rm -rf




all: main libatspprint.a

libatspprint.a: pprint.dats pprint.sats
	$(PATSOPT) -o pprint_dats.c -d pprint.dats
	$(CC) $(CCFLAGS) -c pprint_dats.c -o pprint_dats.o
	$(AR) libatspprint.a pprint_dats.o

clean: 
	$(RMF) *ats.c *.o

cleanall:
	$(RMF) *ats.c *.o *.a *.out *.out.dSYM

# test: pprint.dats pprint.sats
	# $(PATSCC) pprint.dats


ATSCC=$(ATSHOME)/bin/atscc \
      -I$(PATSHOME)/src \
      -IATS $(PATSHOME) \
      -IATS $(ATSHOME) \
      -L $(PATSHOME)/utils/libatsyntext -latsyntext \
      -L $(PATSHOME)/utils/libatsopt -latsopt -lgmp

main: 
	$(ATSCC) main.dats
