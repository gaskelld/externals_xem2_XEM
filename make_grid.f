      program make_grid
      real ebeam
      real pmin,pmax,pstep
      real thetamin,thetamax,thetastep
      real ptmp,thtmp
      character*80 xfile
      character(4) mychar

      integer i,j,k

c      open(unit=10,file='grid.txt')
c      write(6,*) 'Enter beam energy'
c      read(5,*) ebeam
c      write(6,*) 'Minimum scattered electron energy'
c      read(5,*) pmin
c      write(6,*) 'Maximum scattered electron energy'
c      read(5,*) pmax
c      write(6,*) 'Scattered electron energy step size'
c      read(5,*) pstep

c      write(6,*) 'Theta min'
c      read(5,*) thetamin
c      write(6,*) 'Theta max'
c      read(5,*) thetamax
c      write(6,*) 'Theta step size'
c      read(5,*) thetastep
c for XEM EMC
c      ebeam=10.551
c      pmin=1.10
c      pmax=4.15
cc      pmax=7.20
c      pstep=0.01
c
c      thetamin=15.0
c      thetamax=41.0
c      thetastep=0.2

c NPS/DVCS stuff
c      ebeam=10.539
c      pmin=4.53
c      pmax=5.55
c      pstep=0.01
c
c      thetamin=14.2
c      thetamax=24.4
c      thetastep=0.2
c 
c x36_4
c      ebeam=8.454
c      pmin=2.30
c      pmax=2.82
c      pstep=0.01

c      thetamin=19.8
c      thetamax=29.8
c      thetastep=0.2

c 3N SRCstuff
      ebeam=10.551
      pmin=7.0
      pmax=8.79
      pstep=0.01

      thetamin=10.0
      thetamax=13.0
      thetastep=0.2

      np=int((pmax-pmin)/pstep)

      nth=int( (thetamax-thetamin)/thetastep)

      do i=1,nth+1
         k=100+i
         thtmp=thetamin+(i-1)*thetastep
         write(mychar,'(f4.1)') thtmp
         xfile='RUNPLAN/10.55gev_th_'//mychar//'deg_src_part1.inp'
         open(unit=10,file=xfile)
         do j=1,np+2
            ptmp=pmin + (j-1)*pstep
            write(10,77) ebeam,ptmp,thtmp
         enddo
         close(10)
      enddo

c      pmin=1.10
      pmin=8.81
      pmax=10.51
      np=int((pmax-pmin)/pstep)
      do i=1,nth+1
         k=100+i
         thtmp=thetamin+(i-1)*thetastep
         write(mychar,'(f4.1)') thtmp
         xfile='RUNPLAN/10.55gev_th_'//mychar//'deg_src_part2.inp'
         open(unit=10,file=xfile)
         do j=1,np+1
            ptmp=pmin + (j-1)*pstep
            write(10,77) ebeam,ptmp,thtmp
         enddo
         close(10)
      enddo


 77   format(F6.3,1x,F7.4,1x,F7.4)

      close(10)
 99   continue
      end
