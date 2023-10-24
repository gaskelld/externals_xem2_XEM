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

      ebeam=10.551
      pmin=1.10
      pmax=4.15
c      pmax=7.20
      pstep=0.01

      thetamin=15.0
      thetamax=41.0
      thetastep=0.2

      np=int((pmax-pmin)/pstep)

      nth=int( (thetamax-thetamin)/thetastep)

      do i=1,nth+1
         k=100+i
         thtmp=thetamin+(i-1)*thetastep
         write(mychar,'(f4.1)') thtmp
         xfile='RUNPLAN/10.55gev_th_'//mychar//'deg_part1.inp'
         open(unit=10,file=xfile)
         do j=1,np+1
            ptmp=pmin + (j-1)*pstep
            write(10,77) ebeam,ptmp,thtmp
         enddo
         close(10)
      enddo

c      pmin=1.10
      pmin=4.16
      pmax=7.20
      do i=1,nth+1
         k=100+i
         thtmp=thetamin+(i-1)*thetastep
         write(mychar,'(f4.1)') thtmp
         xfile='RUNPLAN/10.55gev_th_'//mychar//'deg_part2.inp'
         open(unit=10,file=xfile)
         do j=1,np+1
            ptmp=pmin + (j-1)*pstep
            write(10,77) ebeam,ptmp,thtmp
         enddo
         close(10)
      enddo

 77   format(F6.3,1x,F7.4,1x,F7.4)

      close(10)

      end
