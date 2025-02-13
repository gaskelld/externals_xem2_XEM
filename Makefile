# RHEL9 
#CERN_ROOT = /apps/cernlib/x86_64_rhel7/2005/
#OTHERLIBS = -L$(CERN_ROOT)/lib -lmathlib
FFLAGS    = -C -g -w -fno-automatic -fbounds-check -ffixed-line-length-132
F77       :=gfortran
########################################

externals_all_objs = externals_all.o xem_model.o F1F2IN21_v1.0.o\
	             sig_bar_df.o nform.o smear4all.o\
                     get_cc_info.o dilog64.o
externals_all_srcs = externals_all.f xem_model.f F1F2IN21_v1.0.f\
	             sig_bar_df.f nform.f smear4all.f\
                     get_cc_info.f dilog64.f

########################################

none: externals_all

all:  externals_all

externals_all.o: externals_all.f
		 $(F77) $(FFLAGS) -c $< -o $@

	$(F77) $(FFLAGS) -c $< -o $@

xem_model.o: xem_model.f
	$(F77) $(FFLAGS) -c $< -o $@

smear4all.o: smear4all.f
	$(F77) $(FFLAGS) -c $< -o $@

f1f221.o: f1f221.f
	$(F77) $(FFLAGS) -c $< -o $@

F1F2IN21_v1.0.o: F1F2IN21_v1.0.f
	$(F77) $(FFLAGS) -c $< -o $@

sig_bar_df.o: sig_bar_df.f
	$(F77) $(FFLAGS) -c $< -o $@

nform.o: nform.f
	$(F77) $(FFLAGS) -c $< -o $@

get_cc_info.o: get_cc_info.f
	$(F77) $(FFLAGS) -c $< -o $@

dilog64.o: dilog64.f
	$(F77) $(FFLAGS) -c $< -o $@

externals_all: $(externals_all_objs) Makefile
	$(F77) -o $@  $(FFLAGS) $(externals_all_objs)


clean:
	rm -f *.o externals_all
