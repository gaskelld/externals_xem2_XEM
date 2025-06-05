!-----------------------------------------------------------------------------
CAM Main subroutine used in externals.
!-----------------------------------------------------------------------------
      subroutine SIGMODEL_CALC(E0in,EPin,THETAin,iZ,
     >        iA,avgM,DUM1,DUM2,SIGMApass,XFLAG,FACT)
      implicit none
      include 'constants_dble.inc'

      COMMON /Y_SCALING/ ag, bg, bigB, f0, alpha1, pfermi, eps
      real*8 ag, bg, bigB, f0, alpha1, pfermi, eps

      REAL E0in, EPin, THETAin
      REAL DUM1, DUM2, fact, avgM, SIGMApass
      real*8 sigma_send
      real*8 E0, EP, THETA, QSQ, NU, THR
      real*8 Y, A, Z, X, N,m_tgt,cs,sn,tn,elastic_peak
      real*8 INNP, INNT
      real*8 sig_qe_new, sigdis_new
      real*8 YSCALE
      integer iZ, iA, xflag
      logical first/.true./
      logical y_calc_ok
      
      E0 = real(E0in,8)
      EP = real(EPin,8)
      THETA = real(THETAin,8)
      A = dble(iA)
      Z = dble(iZ)
      m_tgt=dble(avgM)

      if(first) then
         first=.false.
         write(6,*) 'calling load_parameters',A,Z
         call load_parameters(A, Z)
      endif

      INNT = 30
      INNP = 30
      N = A - Z
      THR = THETA*pi/180.
      QSQ = 4*E0*EP*(SIN(THR/2))**2
      NU  = E0 - EP
      X   = QSQ/(2*nuc_mass*NU)
      Y   = YSCALE(E0,EP,THR,A,EPS)

      sig_qe_new = 0.0
      sigdis_new = 0.0

      cs = cos(thr/2.)
      sn = sin(thr/2.)
      tn = tan(thr/2.)
      elastic_peak = E0/(1.+2.*E0*sn**2/m_tgt)
      if (EP.gt.elastic_peak) then
         sigma_send=0.0
         SIGMApass = real(sigma_send,4)
         return
      endif

c      write(*,*) 'Y: ', Y
      IF(Y.lt.1.E19) then
         if((XFLAG.eq.1).or.(XFLAG.eq.2)) then
            call sig_qe_calc(Y,iA, iZ,E0,EP, THR, X, sig_qe_new)
            sig_qe_new = sig_qe_new*1000000.0
         endif
         if((XFLAG.eq.1).or.(XFLAG.eq.3)) then
            call sig_dis_calc(iA, iZ, E0, EP, THR, Y, sigdis_new)
            sigdis_new = sigdis_new
         endif
      ELSE
         sigdis_new = 0.0
         sig_qe_new = 0.0
      ENDIF
c 2003 format (2(E13.5,1x))
c      write(14,2003) sigdis_new,sig_qe_new
      !Used to pass to standalone code.  DUM1 and DUM2 not used in externals
      DUM1 = Y
      DUM2 = X
      sigma_send = sig_qe_new + sigdis_new
      SIGMApass = real(sigma_send,4)

      !Incomplete write_corrections.  Needs internal flag as well
      !call write_corrections()

      return
      end

C____________________________________________________________________________
      subroutine xem_model(E0, EP, THETA, A, Z, Ypass, Xpass, 
     >     sigdis_pass, sigqe_pass, reload_params)
      implicit none

!     Parameters passed from/to standalone code
      real*8 E0, EP, THETA, A, Z
      real*8 sigdis_pass, sigqe_pass, Ypass, Xpass
      logical reload_params
      !Parameters to pass to SIGMODEL_CALC
      REAL E0_smc, EP_smc, THETA_smc, Y_smc, X_smc
      REAL FACT, avgM, sigqe_smc, sigdis_smc
      INTEGER XFLAG, A_smc, Z_smc
      logical load_params/.true./
!     Load parameters when input from user table
!      if(reload_params.or.load_params) then
!         call load_parameters(A, Z)
!         load_params=.false.
!      endif

!Convert everything to REAL to send to SIGMODEL_CALC
      E0_smc=REAL(E0)
      EP_smc=REAL(EP)
      THETA_smc=REAL(THETA)
      Z_smc=INT(Z)
      A_smc=INT(A)
      Y_smc=0.0
      X_smc=0.0
      sigqe_smc=0.0
      sigdis_smc=0.0
      
      XFLAG = 2                 !QE
      CALL SIGMODEL_CALC(E0_smc, EP_smc, THETA_smc, Z_smc,
     >     A_smc, avgM, Y_smc, X_smc, sigqe_smc, XFLAG, FACT)
      XFLAG = 3                 !DIS
      CALL SIGMODEL_CALC(E0_smc, EP_smc, THETA_smc, Z_smc,
     >     A_smc, avgM, Y_smc, X_smc, sigdis_smc, XFLAG, FACT)

!Convert everything back to DBLE to send to standalone code.
      Ypass=DBLE(Y_smc)
      Xpass=DBLE(X_smc)
      sigqe_pass=DBLE(sigqe_smc)
      sigdis_pass=DBLE(sigdis_smc)

      return
      end

!-----------------------------------------------------------------------------
CAM Calculate DIS using donal's smearing routine.
!-----------------------------------------------------------------------------
      subroutine sig_dis_calc(a, z, e, ep, thr, y, sigdis)
      implicit none

      COMMON /Y_SCALING/ ag, bg, bigB, f0, alpha1, pfermi, eps
      real*8 ag, bg, bigB, f0, alpha1, pfermi, eps
      COMMON /CORRECTIONS/ johns_fac, fact, corfact, dhxcorfac, emc_corr
      real*8 johns_fac, fact, corfact, dhxcorfac, emc_corr
      real*8 inelastic_it

      include 'constants_dble.inc'
      integer a, z, n, innp, innt
      real*8 e, ep, thr, wsq, x,y, qsq, nu
      real*8 sigdis, pmax
      real*8 f1, f2, w1, w2, tan_2, sig_mott
      real*8 w2qe,q2qe,fl
      integer wfn
      real*8 emc_func_xem
!      include 'model_constants.inc'
      logical firstf1f2

      data firstf1f2/.TRUE./

c needed by f1f2in21
      if(firstf1f2) then
	 write(6,*) 'Initializing F1F2IN21:'  
	 write(6,*) 'F1F2IN21: calling sqesub'
	 q2qe=1.
	 w2qe=1.
	 wfn=2
         call sqesub(w2qe,q2qe,wfn,f1,f2,fL,firstf1f2)
	 firstf1f2=.false.
	endif

      n=a-z
      qsq=4.0*e*ep*sin(thr/2)**2
      nu=e-ep
      x=qsq/2.0/nuc_mass/nu
      WSQ = -qsq + nuc_mass**2 + 2.0*nuc_mass*nu

      PMAX=1.0

      if(a.ge.2) then
         if(WSQ.lt.2.25) then
            innt=30
            innp=30
         else
            innt=30
            innp=10
         endif

         CALL smear4all(E,EP,THR,dble(A),dble(Z),dble(N),eps,PMAX,
     +        dble(INNP),dble(INNT),f0,bigB,ag,bg,
     +        alpha1 ,SIGDIS)

CAM EMC_FUNC specific correction.
CAM D2 set to F1F221.
         emc_corr = emc_func_xem(x,a)
         sigdis = sigdis*emc_corr

CAM Make a correction to the high_x tail.
         dhxcorfac=1.
         if ((x.gt.0.9)) then
            call  dis_highx_cor(a,x,dhxcorfac)
            sigdis = sigdis*dhxcorfac
         endif
         
      else if(A.eq.1) then
       call F1F2IN21(dble(Z),dble(A), QSQ, WSQ, F1, F2)
       W1 = F1/.93827231D0
       W2 = F2/nu
       tan_2 = tan(thr/2)**2
CAM    Mott cross section
       sig_mott = 0.3893857*(alpha*cos(thr/2))**2/(2*e*sin(thr/2)**2)**2
       sigdis =  sig_mott*(W2+2.0*W1*tan_2)*1.e-2*1.e9/10.0
      endif

cDJG   Apply iteration correction      
cDJG      sigdis=sigdis*inelastic_it(x,A,Z) ! skip this for SRC

      end

!-----------------------------------------------------------------------------
      subroutine sig_qe_calc(y, a, z, e, ep, thr, x, sig_qe)
      implicit none
      include 'constants_dble.inc'

      COMMON /Y_SCALING/ ag, bg, bigB, f0, alpha1, pfermi, eps
      real*8 ag, bg, bigB, f0, alpha1, pfermi, eps
      COMMON /JOHNS_FAC/ j_fac
      real*8 j_fac
      COMMON /CORRECTIONS/ johns_fac, fact, corfact, dhxcorfac, emc_corr
      real*8 johns_fac, fact, corfact, dhxcorfac, emc_corr

      integer a, z
      real*8 thr, y, e, ep, x, nu, q4_sq, q3v
      real*8 sig_qe, sigma_n, sigma_p
      real*8 dwdy
      real*8 tail_cor
!      include 'model_constants.inc'

      q4_sq = 4.*e*ep*sin(thr/2.)**2 !4-mom. transf. squared.
      nu = e-ep                 !Energy loss
      q3v = sqrt(q4_sq + nu**2) !3-momentum transfer
      dwdy = q3v/sqrt(nuc_mass**2+q3v**2+y**2+2.0*q3v*y)
      x=q4_sq/2.0/nuc_mass/nu

CAM F(y) from Nadia's Thesis based on:
CAM https://arxiv.org/pdf/nucl-th/9702009.pdf
      y=y*1000
      if(a.eq.2.) then
        sig_qe = (f0-bigB)*alpha1**2*exp(-(ag*y)**2)
     +    /(alpha1**2+y**2)+bigB*exp(-bg*abs(y))
      else
        sig_qe = (f0-bigB)*alpha1**2*exp(-(ag*y)**2)
     +    /(alpha1**2+y**2)+bigB*exp(-(bg*y)**2)
      endif
      y=y/1000.
CAM JOHNS_FAC basically linear factor less than X=1
      if(j_fac.ne.0.0) then
         johns_fac=max(1.,1.+y*1.4*j_fac)
      else
         johns_fac=1.
      endif
      sig_qe=johns_fac*sig_qe

CAM Make get the off-shell contributions based on DeForest:
CAM T. De Forest, Jr. Nuc. Phys. A392 232 (1983)
      call sig_bar_df(e, ep, thr*180/pi, y,dble(0.0), sigma_p, sigma_n)
      fact = (Z*sigma_p+(A-Z)*sigma_n)/dwdy
      sig_qe=sig_qe*fact*1000.

CAM tail_cor applied here
      corfact=tail_cor(x)
      sig_qe=sig_qe*corfact

      return
      end

!---------------------------------------------------------------------
CAM Function to determine Y.  Refer to John A's thesis
!---------------------------------------------------------------------
      real*8 FUNCTION YSCALE(E,EP,THR,A,EPS)
      IMPLICIT NONE
      INCLUDE 'constants_dble.inc'
      real*8 E, EP,THR,A, NU,W,WP,AG,BG,PART1,PART2,PART3,EPS,QSQ,CG
      real*8 backup,RAD

      yscale = 0.0
      NU = E-EP
      QSQ = 4*E*EP*(SIN(THR/2))**2

      W = NU+A*NUC_MASS-EPS
      WP = W**2+((A-1)*NUC_MASS)**2-NUC_MASS**2
                                !write (15,*) 'w, wp, qsq', w,wp,qsq
      AG = 4*W**2-4*(NU**2+QSQ)
      BG = SQRT(NU**2+QSQ)*(4*WP-4*(NU**2+QSQ))
      PART1 = 4*W**2*(((A-1)*NUC_MASS)**2)
      PART2 = 2*WP*(QSQ+NU**2)
      PART3 = (QSQ+NU**2)**2
      CG = PART1+PART2-PART3-WP**2
      rad = BG**2-4*AG*CG
                                !write (15,*) 'A, B, C, RAD', AG,BG,CG,RAD
      if (rad.ge.0) then
         YSCALE = (-BG+SQRT(BG**2-4*AG*CG))/(2*AG)
         backup = (-BG-SQRT(BG**2-4*AG*CG))/(2*AG)
      else
         YSCALE = 1.E20
      endif

      RETURN
      END

!-----------------------------------------------------------------------------------------------------

      subroutine dis_highx_cor(anuc,x,cor)
      implicit none
      
      COMMON /DHX_COR/ dhx_xlow,dhx_xhigh,dhx_cor_min,dhx_cor_xalt,
     >     dhx_cor_alt_val, dhx_cor_0, dhx_cor_1
      real*8 dhx_xlow,dhx_xhigh,dhx_cor_min,dhx_cor_xalt,
     >     dhx_cor_alt_val, dhx_cor_0, dhx_cor_1
      
      integer anuc
      real*8 x,cor, frac

      frac=1
      if (x.gt.dhx_xlow) then
         cor=dhx_cor_1*x+ dhx_cor_0
         if((x.ge.dhx_xlow).and.(x.le.dhx_xhigh)) then
            frac = (x-dhx_xlow)/(dhx_xhigh-dhx_xlow)
         endif
      endif
      if (x.gt.dhx_cor_xalt.and.dhx_cor_xalt.ne.0.0) then
         cor=dhx_cor_alt_val
      endif
      cor=frac*cor+1.-frac

      if(cor.lt.0.4) cor=0.4
         
      return
      end

c--------------------------------------------------------------------------------
CAM tail_cor used to fix tail of QE cross-section.
c--------------------------------------------------------------------------------
      real*8 function tail_cor(x)
      implicit none

      COMMON /QE_TAIL_COR/ tc_xlow, tc_xhigh, tc_aa, tc_bb, tc_cc, 
     >       tc_dd, tc_ee, tc_ff, tc_const
      real*8 tc_xlow, tc_xhigh, tc_aa, tc_bb, tc_cc, 
     >       tc_dd, tc_ee, tc_ff, tc_const
      real*8  x, x_cor, corfact, my_frac!, aa, bb, cc, dd, ee, ff

      if(x.gt.tc_const) then
         x_cor = tc_const
      else
         x_cor=x
      endif
      corfact=1
      if((x.ge.(tc_xlow))) then
         corfact=(tc_aa*exp(tc_bb*x_cor) + 
     1   tc_cc*x_cor**6+tc_dd*x_cor**4+tc_ee*x_cor**2+tc_ff)
         if(x.lt.(tc_xhigh)) then
	    my_frac=(x-tc_xlow)/(tc_xhigh-tc_xlow)
            corfact=my_frac*corfact+(1.-my_frac)
         endif
      endif

      tail_cor=corfact
      return
      end

!this is the postthesis iteration of daves
      real*8 function emc_func_xem(x,A) ! now compute the emc effect from our own fits.
      implicit none

      COMMON /EMC_COR/ emc_xlow, emc_xhigh, emc_0, emc_1, emc_2, emc_3,
     >       emc_4, emc_5
      real*8 emc_xlow, emc_xhigh, emc_0, emc_1, emc_2, emc_3,
     >       emc_4, emc_5

      integer a
      real*8 x, xtmp, frac
      real*8 emc, emc_corr

      if(x.lt.0.2) then
         xtmp=0.2
      else
         xtmp = x
      endif

      emc = emc_0 + emc_1*xtmp + emc_2*xtmp**2 +
     1     emc_3*xtmp**3 + emc_4*xtmp**4 + emc_5*xtmp**5
c      write(6,*) emc

c      emc = 1.42308 - 2.65087*xtmp + 11.41047*xtmp**2 -
c     1     22.54747*xtmp**3 + 18.47078*xtmp**4 - 5.07537*xtmp**5
c      write(6,*) emc
        
!FROM SIG_DIS_CALC
!CAM EMC_FUNC specific correction.
!CAM D2 set to F1F221.
      if (x.lt.emc_xlow) then
         emc_corr = emc
      elseif ((x.ge.emc_xlow).and.(x.lt.emc_xhigh)) then
         frac = (x-emc_xlow)/(emc_xhigh-emc_xlow)
         emc_corr = 1.0*frac + emc*(1.-frac)
CAM Uncomment when setting emc_func_xem
CAM           emc_corr = emc
      elseif(x.ge.emc_xhigh) then
         emc_corr = 1.0
      endif
      
      emc_func_xem= emc_corr
      return
      end
      

      integer*4 function last_char(string)
C+______________________________________________________________________________
!
! LAST_CHAR - Return the position of the last character in the string which
! is neither a space or a tab. Returns zero for null or empty strings.
C-______________________________________________________________________________

      implicit none
      integer*4 i
      character*(*) string
      character*1 sp/' '/
      character*1 tab/'	'/
      
      save
      
C ============================= Executable Code ================================

      last_char = 0
!     write(*,*) 'LAST CHAR ROUTINE INPUT: ',string
!     write(*,*) 'LAST CHAR ROUTINE SP and TAB: ',sp,tab
      do i = 1,len(string)
         if (string(i:i).ne.sp.and.string(i:i).ne.tab) last_char = i
!     write(*,*) 'LAST CHAR ROUTINE LOOP: ',string(i:i),i
      enddo
!     write(*,*) 'LAST CHAR ROUTINE RESULT: ',last_char
      
      return
      end

      recursive subroutine load_parameters(a, ztmp)
      implicit none

      COMMON /Y_SCALING/ ag, bg, bigB, f0, alpha1, pfermi, eps
      real*8 ag, bg, bigB, f0, alpha1, pfermi, eps
      COMMON /JOHNS_FAC/ j_fac
      real*8 j_fac
      COMMON /QE_TAIL_COR/ tc_xlow, tc_xhigh, tc_aa, tc_bb, tc_cc, 
     >       tc_dd, tc_ee, tc_ff, tc_const
      real*8 tc_xlow, tc_xhigh, tc_aa, tc_bb, tc_cc, 
     >       tc_dd, tc_ee, tc_ff, tc_const
      COMMON /EMC_COR/ emc_xlow, emc_xhigh, emc_0, emc_1, emc_2, emc_3,
     >       emc_4, emc_5
      real*8 emc_xlow, emc_xhigh, emc_0, emc_1, emc_2, emc_3,
     >       emc_4, emc_5
      COMMON /DHX_COR/ dhx_xlow,dhx_xhigh,dhx_cor_min,dhx_cor_xalt,
     >       dhx_cor_alt_val, dhx_cor_0, dhx_cor_1
      real*8 dhx_xlow,dhx_xhigh,dhx_cor_min,dhx_cor_xalt,
     >       dhx_cor_alt_val, dhx_cor_0, dhx_cor_1

      logical found, first/.true./
      integer*4 i,j
      real*8 a, z, ztmp
      real*8 parmlist(32)

      include 'xem_parameters.inc'


      if(a.eq.3) then
         z=2.0 ! use same parameters for 3He and 3H
         if(ztmp.eq.1.0) then
            write(6,*) 'Notice: Using 3He parameters for 3H'
         endif
      else
         z=ztmp
      endif

C Get target specific stuff from lookup table.

      found = .false.
      write(6,*) 'looking up model parameters'
      do i = 1,10               !loop over known targets.
         if (lookup(i,1).eq.z.and.float(int(a)).eq.lookup(i,2)) then
	    found = .true.
	    do j = 1,32
               parmlist(j) = lookup(i,j+3)
               write(6,*) parmlist(j)
	    enddo
         endif
      enddo

      EPS = parmList(2)
      f0  =  parmList(3)
      bigB =  parmList(4)
      ag =  parmList(5)
      bg =  parmList(6)
      alpha1 =  parmList(7)

      j_fac = parmList(8)

      tc_const = parmList(9)
      tc_xlow = parmList(10)
      tc_xhigh = parmList(11)
      tc_aa = parmList(12)
      tc_bb = parmList(13)
      tc_cc = parmList(14)
      tc_dd = parmList(15)
      tc_ee = parmList(16)
      tc_ff = parmList(17)

      emc_xlow  = parmList(18)
      emc_xhigh = parmList(19)
      emc_0     = parmList(20)
      emc_1     = parmList(21)
      emc_2     = parmList(22)
      emc_3     = parmList(23)
      emc_4     = parmList(24)
      emc_5     = parmList(25)

      dhx_xlow        = parmList(26)
      dhx_xhigh       = parmList(27)
      dhx_cor_min     = parmList(28)
      dhx_cor_0       = parmList(29)
      dhx_cor_1       = parmList(30)
      dhx_cor_xalt    = parmList(31)
      dhx_cor_alt_val = parmList(32)

c      write(6,*) EPS, f0, bigB, ag, bg, alpha1

c      write(6,*) emc_xlow, emc_xhigh, emc_0, emc_1, emc_2, emc_3, emc_4,
c     + emc_5

c      write(6,*) dhx_xlow, dhx_xhigh, dhx_cor_min, dhx_cor_0, dhx_cor_1,
c     + dhx_cor_xalt, dhx_cor_alt_val

      if (.not.found.and.first) then
         write(6,*) 'cant find target in lookup table!'
         if(a.gt.4 .and. a.lt.20.0) then
            write(6,*) 'Using Carbon parameters with given A and Z...'
            first=.false.
            call load_parameters(dble(12.),dble(6.))
            return              !Quit if couldn't find info.
         elseif(a.ge.20.0 .and. a.le.80) then
            write(6,*) 'Using Copper parameters with given A and Z...'
            first=.false.
            call load_parameters(dble(64.),dble(29.))
            return              !Quit if couldn't find info.
         elseif(a.gt.80.0) then
            write(6,*) 'Using Gold parameters with given A and Z...'
            first=.false.
            call load_parameters(dble(197.),dble(79.))
            return              !Quit if couldn't find info.
         endif
      else if(.not.found.and. .not. first) then
         write(6,*) 'Something is wrong with default load!',A
      endif
      
      return
      end

      subroutine write_corrections()
      implicit none
      COMMON /CORRECTIONS/ johns_fac, fact, corfact, dhxcorfac, emc_corr
      real*8 johns_fac, fact, corfact, dhxcorfac, emc_corr
      logical first/.true./

      if(first) then
         first=.false.
c         write(6,*) "johns_fac fact*1000. corfact dhxcorfac emc_corr"
      endif
c      write(6,*) johns_fac, fact*1000., corfact, dhxcorfac, emc_corr
      return
      end
****************************************************************************
	real*8 function inelastic_it(x,A,Z)
C DJG: Correction to inelastic cross section
C DJG: Just a simple one-pass iteration.
        integer A,Z
	real*8 x
	real*8 p(7)
	real*8 x1,x2,xit
        integer i


	inelastic_it = 1.0 ! set to 1 by default

        x1=0.1823
        x2=1.0139
        if(A.eq.1) x2=0.9572

        if(x.lt.x1) then
           xit=x1
        elseif(x.gt.x2) then
           xit=x2
        elseif(x.ge.x1 .and. x.le.x2) then
           xit=x
        endif
c initialize p(i)
        p(1)=1.0
        do i=2,7
           p(i)=0.0
        enddo

        if(A.eq.1) then ! hydrogen
           p(1)=0.96922
           p(2)=-0.58741
           p(3)=3.7553
           p(4)=-9.3335
           p(5)=13.205
           p(6)=-11.311
           p(7)=4.2704
	elseif(A.eq.2) then !deuterium
c           p(1)=0.79327
c           p(2)=2.9495
c           p(3)=-19.238
c           p(4)=59.883
c           p(5)=-94.896
c           p(6)=73.851
c           p(7)=-22.449
           p(1) = 0.96120
           p(2) = -0.61648E-01
           p(3) = 0.29168
           p(4) =-0.29011  
        elseif(A.eq.3) then    !helium3
           p(1)=0.56469
           p(2)=5.1541
           p(3)=-28.901
           p(4)=80.232
           p(5)=-116.16
           p(6)=83.866
           p(7)=-23.910
        elseif(A.eq.4) then     !helium4
           p(1)=0.79470
           p(2)=2.1825
           p(3)=-12.028
           p(4)=29.960
           p(5)=-36.611
           p(6)=20.912
           p(7)=-4.3400
        elseif(A.eq.6) then     !lithium6
           p(1)=0.81582
           p(2)=3.1956
           p(3)=-16.521
           p(4)=38.588
           p(5)=-43.048
           p(6)=21.622
           p(7)=-3.8123
        elseif(A.eq.7) then     !lithium7
           p(1)=1.1981
           p(2)=-2.4732
           p(3)=15.570
           p(4)=-52.401
           p(5)=93.769
           p(6)=-82.069
           p(7)=27.320
        elseif(A.eq.9) then     !beryllium
           p(1)=0.79139
           p(2)=2.8585
           p(3)=-15.744
           p(4)=39.718
           p(5)=-48.440
           p(6)=27.168
           p(7)=-5.2595
        elseif(A.eq.10) then     !boron10
           p(1)=1.0680
           p(2)=-1.4093
           p(3)=9.0964
           p(4)=-32.150
           p(5)=60.150
           p(6)=-54.491
           p(7)=18.576
        elseif(A.eq.11) then    !boron11
           p(1)=0.82044
           p(2)=2.1195
           p(3)=-9.7074 
           p(4)=17.675
           p(5)=-9.3719
           p(6)=-5.6220
           p(7)= 4.9996
	elseif(A.eq.12) then !Carbon
           p(1)=0.89088
           p(2)=1.3215
           p(3)=-6.8832
           p(4)=16.371
           p(5)=-18.783
           p(6)=10.107
           p(7)=-2.0906
	elseif(A.eq.27) then !Aluminum
           p(1)=1.2669
           p(2)=-3.9566
           p(3)=24.161
           p(4)=-78.087
           p(5)=134.74
           p(6)=-114.32 
           p(7)=36.968
	elseif(A.eq.40) then    !Calcium-40
           p(1)=0.79461
           p(2)=2.3851
           p(3)=-9.1684
           p(4)=11.288
           p(5)=8.8146
           p(6)=-26.516
           p(7)=13.398
	elseif(A.eq.48 .and. Z.eq.20) then !Calcium-48
           p(1)=0.80604
           p(2)=2.8389
           p(3)=-12.205
           p(4)=20.240
           p(5)=-3.6777
           p(6)=-18.099
           p(7)=11.227        
	elseif(A.eq.48 .and. Z.eq.22) then !Titanium
           p(1)=1.2111
           p(2)=-3.2023
           p(3)=21.262 
           p(4)=-71.824
           p(5)=129.15
           p(6)=-114.35 
           p(7)=38.820        
	elseif(A.eq.54) then !Iron-54
           p(1)=1.1248
           p(2)=-2.3312
           p(3)=16.959
           p(4)=-61.142
           p(5)=114.48
           p(6)=-103.81
           p(7)=35.746        
        elseif(A.eq.58 .and. Z.eq.28) then !Nickel-58
           p(1)=1.2151
           p(2)=-3.4945
           p(3)=22.899
           p(4)=-77.058
           p(5)=137.91
           p(6)=-121.72
           p(7)=41.259
	elseif(A.eq.64 .and. Z.eq.28) then !Nickel-64
           p(1)=1.5384
           p(2)=-7.5679
           p(3)=42.612
           p(4)=-123.74
           p(5)=195.70
           p(6)=-157.25
           p(7)=49.752
        elseif(Z.eq.29) then    !Copper
           p(1)=0.69955
           p(2)=3.7674
           p(3)=-17.444
           p(4)=33.989
           p(5)=-24.048
           p(6)=-2.1028
           p(7)=6.1204
        elseif(A.eq.108) then   !silver
           p(1)=1.1093
           p(2)=-1.8221
           p(3)=14.861
           p(4)=-58.950
           p(5)=120.38
           p(6)=-116.63
           p(7)=42.125
        elseif(A.eq.197) then   !gold
           p(1)=0.99324
           p(2)=-0.33820
           p(3)=4.2646
           p(4)=-24.689
           p(5)=63.397
           p(6)=-69.495
           p(7)=26.877 
        elseif(A.eq.232) then    !thorium
           p(1)=1.2512
           p(2)=-4.4240
           p(3)=27.738
           p(4)=-89.062
           p(5)=156.03
           p(6)=-136.86 
           p(7)=46.361
        endif

        inelastic_it=p(1)+p(2)*xit+p(3)*xit**2+p(4)*xit**3
     >        +p(5)*xit**4+p(6)*xit**5+p(7)*xit**6

	return
	end
