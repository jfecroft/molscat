      SUBROUTINE AIPROP(NCH,MXLAM,NPOTL,
     1                  Z,TMAT,W,VL,IV,EINT,CENT,P,
     2                  Y1,Y2,CC,Y4,VECNOW,VECNEW,
     3                  EIGOLD,EIGNOW,HP,
     4                  RSTART,RSTOP,NSTEP,DRNOW,POWR,TOLHI,NODES,
     5                  ERED,RMLMDA,IPRINT)
C  This subroutine is part of the MOLSCAT, BOUND and FIELD suite of programs
C
C  AUTHOR:  MILLARD ALEXANDER
C  CURRENT REVISION DATE: 4-FEB-1991
C
C  AIRY ZEROTH-ORDER PROPAGATOR FROM R=RSTART TO R=RSTOP
C  FOR REFERENCE SEE M. ALEXANDER, "HYBRID QUANTUM SCATTERING
C                    ALGORITHMS ..." J. CHEM. PHYS. 81, 4510 (1984)
C                AND M. ALEXANDER AND D. MANOLOPOULOS, "A STABLE LINEAR
C                    REFERENCE POTENTIAL ALGORITHM FOR SOLUTION ..."
C                    J. CHEM. PHYS. 86, 2044 (1987)
C ----------------------------------------------------------------------
C  ADAPTED TO MOLSCAT 4/91 BY TRP@NASAGISS
C  ADAPTED TO MOLSCAT VERSION 11 BY JMH, JUN 92
C  ADAPTED TO WORK WITH BOUND AS WELL AS MOLSCAT BY JMH, NOV 06
C
C  TOLHI>1 ALGORITHM CHANGED BY CRLS, JAN 19
C-----------------------------------------------------------------------
C  DEFINITION OF VARIABLES IN CALL LIST:
C   Z:               MATRIX OF MAXIMUM DIMENSION NCH*NCH
C                    ON ENTRY Z CONTAINS THE INITIAL LOG-DERIVATIVE MATRIX
C                               AT R=RSTART IN THE FREE BASIS
C                    ON RETURN Z CONTAINS THE LOG-DERIVATIVE MATRIX AT R=RSTOP
C   W, TMAT, VECNOW
C    , VECNEW:       SCRATCH MATRICES OF DIMENSION AT LEAST NCH*NCH
C  EIGOLD, EIGNOW
C    , HP, Y1, Y2
C    , CC, Y4:       SCRATCH VECTORS OF DIMENSION AT LEAST NCH
C  XF:               ON ENTRY: CONTAINS INITIAL VALUE OF INTERPARTICLE
C                              DISTANCE
C                    ON EXIT:  CONTAINS FINAL VALUE OF INTERPARTICLE
C                              DISTANCE
C                              THIS IS EQUAL TO RSTOP IF NORMAL
C                              TERMINATION
C                              OTHERWISE AN ERROR MESSAGE IS PRINTED
C  DRNOW:            ON ENTRY:  CONTAINS INITIAL INTERVAL SIZE
C                    ON EXIT:  CONTAINS FINAL INTERVAL SIZE
C  ERED:             INTERACTION ENERGY IN ATOMIC UNITS
C  TOLHI:            PARAMETER TO DETERMINE STEP SIZES
C                    IF 0 < TOLHI < 1, THEN ESTIMATED ERRORS ARE USED TO
C                    DETERMINE NEXT STEP SIZES FOLLOWING THE PROCEDURE
C                    OUTLINED IN M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING
C                    ALGORITHMS ..."
C                    IF TOLHI = 0, THEN STEP SIZES ARE CALCULATED FROM
C                    AN ARITHMETIC SERIES IN R**1/POWR
C  POWR:             POWER AT WHICH STEP SIZES INCREASE
C
C
C  LOGICAL VARIABLES:
C     ISYM:         IF .TRUE., PROPAGATION ASSUMES SYMMETRY OF Y MATRIX
C ----------------------------------------------------------------------
      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      LOGICAL ISYM
C
C  COMMON BLOCK FOR CONTROL OF USE OF PROPAGATION SCRATCH FILE
      LOGICAL IREAD,IWRITE
      COMMON /PRPSCR/ ESHIFT,ISCRU,IREAD,IWRITE
C
      INTEGER I, IEND, KOUNT, ITWO, IZERO, KSTEP, MAXSTP,
     :        NCH, NPT, NSKIP, NODES
      EXTERNAL CORR, TRNSFM, OUTMAT, POTENT, DAXPY, DCOPY,
     :         SYMINV, SPROPN, DSCAL, TRNSP, WAVEIG
C  MATRIX DIMENSIONS (ROW DIMENSION = NCH, MATRICES STORED COLUMN BY COLUMN
      DIMENSION Z(1), W(1), TMAT(1), VECNOW(1), VECNEW(1)
C  VECTORS DIMENSIONED NCH
      DIMENSION EIGOLD(1), EIGNOW(1), HP(1), Y1(1), Y2(1), CC(1), Y4(1)
      DIMENSION P(1),VL(1),IV(1),EINT(1),CENT(1)

      DATA IZERO, IONE, ZERO, ONE /0, 1, 0.D0, 1.D0/
      DATA ISYM /.TRUE./
C
C ----------------------------------------------------------------------
C
      XF = RSTART
      IF (IREAD)      ITWO = 1
      IF (IWRITE)     ITWO = 0
      IF (ISCRU.EQ.0) ITWO = -1
      DRNORM = DRNOW
      NODES = 0
      SPCMX = 0.D0
      SPCMN = ABS(RSTOP - RSTART)
C  DETERMINE LOCAL WAVEVECTORS AT RSTART TO USE IN ESTIMATING SECOND
C  DERIVATIVES.  HP IS USED AS A SCRATCH VECTOR HERE
      CALL WAVEIG(W, EIGOLD, HP, Y1, RSTART, NCH, P, MXLAM, VL,
     1            IV, RMLMDA, ERED, EINT, CENT, NPOTL, IPRINT)
C  LOCAL WAVEVECTORS AT RSTART ARE RETURNED IN EIGOLD
C
C  ORIGINAL MAXSTP FORMULA CAN OVERFLOW SO HARD-CODE IT. JMH 8/2012
C     MAXSTP = ( (RSTOP-XF) / DRNOW ) * 20
      MAXSTP = 500000
      IF (ISCRU.EQ.0) GOTO 61
      IF (IWRITE) WRITE(ISCRU) MAXSTP,ERED
      IF (IREAD) THEN
        READ(ISCRU) MAXSTP,EFIRST
        ESHIFT=ERED-EFIRST
      ENDIF
      CALL OUTMAT(TMAT, EIGOLD, HP, ESHIFT, DRNOW, RNOW,
     :            NCH, NCH, ITWO, ISCRU)
C
 61   CONTINUE
C
      IF (.NOT.IREAD) THEN
        DRMID = DRNOW * 0.5D0
        RLAST = XF
        RNOW = RLAST + DRMID
        RNEXT = RLAST + DRNOW
C  DEFINE LOCAL BASIS AT RNOW AND CARRY OUT TRANSFORMATIONS
C  VECNEW IS USED AS SCRATCH MATRIX AND Y1 IS USED AS SCRATCH VECTOR
C  HERE
        CALL POTENT(W, VECNOW, VECNEW, EIGNOW, HP, Y1, RNOW, DRNOW,
     1              XLARGE, NCH, P, MXLAM, VL, IV, RMLMDA,
     2              ERED, EINT, CENT, NPOTL, IPRINT)
C  VECNOW IS TRANSFORMATION FROM FREE BASIS INTO LOCAL BASIS
C  IN FIRST INTERVAL
C  E.G. P1=VECNOW  ; SEE EQ.(23) OF
C  M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING ALGORITHMS ..."
C  STORE VECNOW IN TMAT
        CALL DCOPY(NCH*NCH, VECNOW, 1, TMAT, 1)
C  DETERMINE APPROXIMATE VALUES FOR DIAGONAL AND OFF-DIAGONAL
C  CORRECTION TERMS
        CALL CORR(EIGNOW, EIGOLD, HP, DRNOW, DRMID, XLARGE, CDIAG,
     :            COFF, NCH)
        XF = RSTOP
        IF (IPRINT.GE.20) THEN
          WRITE(6, 40)
40        FORMAT(/'  ** AIRY PROPAGATION (NO DERIVATIVES):')
          WRITE(6, 50)
50        FORMAT('   STEP',4X,'RNOW',7X,'DRNOW',6X,'CDIAG',7X,'COFF')
        ENDIF
      ENDIF
60    IEND = 0
C  WRITE OR READ RELEVANT INFORMATION
      IF (ISCRU.NE.0) CALL OUTMAT(TMAT, EIGOLD, HP, ESHIFT, DRNOW, RNOW,
     :                            NCH, NCH, ITWO, ISCRU)
C
C ----------------------------------------------------------------------
      IF (DRNORM.LT.0.D0 .AND. TOLHI.EQ.0.D0) THEN
        DRNOW=DRNORM
      ENDIF

C  START AIRY PROPAGATION
      DO 200  KSTEP = 1, MAXSTP
        IF (ABS(DRNOW).LT.1D-10) GOTO 249
C  TRANSFORM LOG-DERIV MATRIX FROM LOCAL BASIS IN LAST INTERVAL TO
C  LOCAL BASIS IN PRESENT INTERVAL.  SEE EQ.(23) OF
C  M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING ALGORITHMS ..."
C  W IS USED AS SCRATCH MATRIX HERE, AND Y1 IS SCRATCH ARRAY
C
        CALL TRNSP(TMAT, NCH)
        CALL TRNSFM(TMAT, Z, W, NCH, .FALSE., ISYM )
C
C  TMAT IS NO LONGER NEEDED
C  SOLVE FOR LOG-DERIVATIVE MATRIX AT RIGHT-HAND SIDE OF
C  PRESENT INTERVAL.  THIS USES NEW ALGORITHM OF
C  MANOLOPOULOS AND ALEXANDER, NAMELY
C               (N)    (N)      -1   (N)      (N)
C     Z    = - Y    [ Y    + Z ]    Y     +  Y
C      N+1      2      1      N      2        4
C  WHERE Y  , Y  , AND Y   ARE THE (DIAGONAL) ELEMENTS OF THE "IMBEDDING
C         1    2        4
C  PROPAGATOR" DEFINED IN ALEXANDER AND MANOLOPOULOS
C  DETERMINE THESE DIAGONAL MATRICES FOR PROPAGATION OF LOG-DERIV MATRIX
C  EQS. (38)-(44) OF M. ALEXANDER AND D. MANOLOPOULOS, "A STABLE LINEAR
C                    REFERENCE POTENTIAL ALGORITHM FOR SOLUTION ..."
C
        CALL SPROPN(DRNOW, EIGOLD, HP, Y1, Y4, Y2, NCH)
C
C  SET UP MATRIX TO BE INVERTED
C  NSKIP IS SPACING BETWEEN DIAGONAL ELEMENTS OF MATRIX STORED COLUMN BY
C  COLUMN
C
        NSKIP = NCH + 1
        CALL DAXPY(NCH, ONE, Y1, 1, Z, NSKIP)
C
C  INVERT (Y  +  Z )
C           1     N
C
        CALL SYMINV(Z, NCH, NCH, KOUNT)

        IF (RSTOP.GT.RSTART) THEN
          NODES=NODES+KOUNT
        ELSE
          NODES=NODES+NCH-KOUNT
        ENDIF
        CALL DSYFIL('U', NCH, Z, NCH)
        IF (KOUNT.GT.NCH) THEN
          WRITE(6, 80)
80        FORMAT('  *** INSTABILITY IN SYMINV IN AIPROP.')
          STOP
        ENDIF
C
C                            -1
C  EVALUATE  - Y  ( Y  + Z )    Y
C               2    1    N      2
C  IN THE NEXT LOOPS EVALUATE THE FULL, RATHER THAN LOWER TRIANGLE
C
        NPT = 1
        DO 85  I = 1, NCH
          FACT = Y2(I)
          CALL DSCAL(NCH, FACT, Z(NPT), 1)
          NPT = NPT + NCH
85      CONTINUE
C                            -1
C  Z NOW CONTAINS ( Y  + Z )    Y  , THIS IS G(N-1,N) IN THE LOCAL BASIS
C                     1    N      2
C
        DO 110  I = 1, NCH
          FACT = - Y2(I)
          CALL DSCAL(NCH, FACT, Z(I), NCH)
110     CONTINUE
C
C  ADD ON  Y
C           4
        CALL DAXPY(NCH, ONE, Y4, 1, Z, NSKIP)
C
        IF (ITWO.GT.0) GOTO 160
C
C  OBLIGATORY WRITE OF STEP INFORMATION IF DEVIATIONS FROM LINEAR
C  POTENTIAL ARE UNUSUALLY LARGE
C  (CRLS 10-2018 RESTRICTED TO IPRINT>=1)
C
C  THIS IS ONLY DONE IF TOLHI .LT. 1, IN WHICH CASE THE LARGEST
C  CORRECTION IS USED TO ESTIMATE THE NEXT STEP
C
        IF (TOLHI.GT.0.D0 .AND. TOLHI.LT.1.D0) THEN
          CMAX = MAX(ABS(CDIAG), ABS(COFF))
          IF (IPRINT.GE.1) THEN
            IF (CMAX.GT.(5.D0 * TOLHI)) THEN
              WRITE(6,125)
125           FORMAT('  ** ESTIMATED CORRECTIONS LARGER THAN 5*TOLHI ',
     1               'IN AIPROP')
              IF (KSTEP.EQ.1) THEN
                WRITE(6, 130)
130             FORMAT('    THE INITIAL VALUE OF DRNOW (SPAC*FSTFAC) ',
     :                 'IS PROBABLY TOO LARGE')
              ELSE
                WRITE(6, 140)
140             FORMAT('   CHECK FOR DISCONTINUITIES OR UNPHYSICAL ',
     1                 'OSCILLATIONS IN YOUR POTENTIAL')
              ENDIF
              IF (IPRINT.LT.20) THEN
                WRITE(6, 50)
                WRITE(6,150) KSTEP, ABS(RNOW), DRNOW, CDIAG, COFF
              ENDIF
            ENDIF
          ENDIF
        ENDIF
C
C
C  WRITE OUT INFORMATION ABOUT STEP JUST COMPLETED
C
        IF (IPRINT.GE.20) THEN
          WRITE(6,150) KSTEP, ABS(RNOW), DRNOW, CDIAG, COFF
150       FORMAT(I7, 4(1PE12.4))
        ENDIF
C
C
C  GET SET FOR NEXT STEP
C
160     IF (IEND.EQ.1) GOTO 250
        IF (ITWO.GT.0) GOTO 180
C
C
C  IF TOLHI .LT. 1, PREDICT NEXT STEP SIZE FROM LARGEST CORRECTION
C
        DROLD=DRNOW
        IF (TOLHI.GT.0.D0 .AND. TOLHI.LT.1.D0) THEN
C
C  NOTE THAT THE FOLLOWING ALGORITHM IS SLIGHTLY DIFFERENT FROM EQ. (30)
C  OF M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING ALGORITHMS ..."
C  AND THAT THE STEP-SIZE ALGORITHM IS ONLY APPROXIMATELY RELATED TO
C  ANY REAL ESTIMATE OF THE ERROR
C  COFF AND CDIAG SHOULD BE APPROXIMATELY TOLHI, SO FROM EQ. (27):
C  DRNOW(AT N+1) = (12 TOLHI/KBAR(N+1)W(N+1)-TILDA')**(1/3)
C  WHICH IS APPROX = (12 TOLHI/KBAR(N)W(N)-TILDA')**(1/3)
C                  = ((12 COFF/KBAR W-TILDA') (TOLHI/COFF))**(1/3)
C                  = DRNOW(AT N) (TOLHI/COFF)**(1/3)
C  OR FROM EQ. (29):
C                   DRNOW = DRNOW (TOLHI/CDIAG)**(1/3)
C
C  SG AND JMH MODIFICATIONS:
C     THE ORIGINAL STEP SIZE ALGORITHM WAS
C         DRNOW = DRNOW * (TOLHI/CMAX) ** (1.D0 / POWR)
C     BUT IT IS MORE REASONABLE TO LIMIT INCREMENT/DECREMENT FOR STABILITY
          FACTOR=(TOLHI/CMAX)**(1.D0/POWR)
C  ALSO NEED TO BE MORE CONSERVATIVE FOR INWARDS PROPAGATION
          IF (DRNOW.LT.0.D0) FACTOR=FACTOR*(1.D0+DRNOW/RNEXT)**POWR
          IF (FACTOR.GT.2.D0) FACTOR=2.D0
          DRNOW = DRNOW * FACTOR
C
        ELSEIF (TOLHI.EQ.0.D0) THEN
C
C  IF TOLHI = 0, CALCULATE NEXT STEP FROM ARITHMETIC SERIES IN R**1/POWR
C
          DRNOW=DRCALC(RSTART,RSTOP,KSTEP,NSTEP,POWR)
C         IF (DRNOW.GT.0.D0) DRNOW = TOLHI * DRNOW
C         IF (DRNOW.LT.0.D0) DRNOW = DRNOW / TOLHI
        ENDIF
C
C  DRNOW IS STEP SIZE IN NEXT INTERVAL
C
        RLAST = RNEXT
        RNEXT = RNEXT + DRNOW
C       IF (RSTOP.GT.RSTART .AND. RNEXT.LT.RSTOP) GOTO 170
C       IF (RSTOP.LT.RSTART .AND. RNEXT.GT.RSTOP) GOTO 170
        IF ((RSTOP-RSTART)*(RSTOP-RNEXT).GT.0.D0) GOTO 170

        IEND = 1
        RNEXT = RSTOP
        DRNOW = RNEXT - RLAST
170     RNEW = RLAST + 0.5D0 * DRNOW
        IF (KSTEP.GT.1 .AND. IEND.NE.1) THEN
          IF (ABS(DRNOW).LT.SPCMN) SPCMN = ABS(DRNOW)
          IF (ABS(DRNOW).GT.SPCMX) SPCMX = ABS(DRNOW)
        ENDIF
        DRMID = RNEW - RNOW
C
C
C  RESTORE EIGENVALUES
C
        CALL DCOPY(NCH, EIGNOW, 1, EIGOLD, 1)
C
C  DEFINE LOCAL BASIS AT RNEW AND CARRY OUT TRANSFORMATIONS
C  TMAT IS USED AS SCRATCH MATRIX AND Y1 IS USED AS SCRATCH VECTOR HERE
C
        CALL POTENT(W, VECNEW, TMAT, EIGNOW, HP, Y1, RNEW, DRNOW,
     1              XLARGE, NCH, P, MXLAM, VL, IV, RMLMDA,
     2              ERED, EINT, CENT, NPOTL, IPRINT)
C
C
C  DETERMINE MATRIX TO TRANSFORM LOG-DERIV MATRIX INTO NEW INTERVAL
C  SEE EQ. (22) OF M.H. ALEXANDER, "HYBRID QUANTUM SCATTERING
C  ALGORITHMS ..."
C
        CALL DGEMUL(VECNEW, NCH, 'N', VECNOW, NCH, 'T', TMAT, NCH,
     1              NCH, NCH, NCH)
        CALL DCOPY(NCH*NCH, VECNEW, 1, VECNOW, 1)
C
C
C  RESTORE RADIUS VALUES
C
        RNOW = RNEW
C
C
C  DETERMINE APPROXIMATE VALUES FOR DIAGONAL AND OFF-DIAGONAL
C  CORRECTION TERMS
C
        CALL CORR(EIGNOW, EIGOLD, HP, DRNOW, DRMID, XLARGE, CDIAG,
     :            COFF, NCH)
        IF (ITWO.LT.0) GOTO 200
        IF (IEND.EQ.1) RNOW = - RNOW
C
C
C  WRITE OR READ RELEVANT INFORMATION
C
 180    CALL OUTMAT(TMAT, EIGOLD, HP, ESHIFT, DRNOW, RNOW,
     :              NCH, NCH, ITWO, ISCRU)
        IF (ITWO.EQ.0) GOTO 200
C
C
C  NEGATIVE RNOW IS CUE FOR LAST STEP IN SECOND ENERGY CALCULATION
C
        IF (RNOW.GT.0.D0) GOTO 200
        RNOW = - RNOW
        IEND = 1
C
C
C  GO BACK TO START NEW STEP
C
 200  CONTINUE
C
C
C  THE FOLLOWING STATEMENT IS REACHED ONLY IF THE PROPAGATION HAS
C  NOT REACHED THE ASYMPTOTIC REGION IN MAXSTP STEPS
C
      WRITE(6,210) MAXSTP, RLAST
 210  FORMAT('  *** AIRY PROPAGATION NOT FINISHED IN', I9,
     :       ' STEPS:  R-FIN SET TO', 1PG11.3,' ***',/)
 249  XF = RLAST
 250  CONTINUE
      NSTEP=KSTEP
      DRNOW=DROLD
      IF (ISCRU.NE.0) CALL OUTMAT(VECNOW, EIGOLD, HP, ESHIFT, DRNOW, XF,
     :                            NCH, NCH, ITWO, ISCRU)
C
C  TRANSFORM LOG-DERIV MATRIX INTO FREE BASIS.  TRANSFORMATION MATRIX IS
C  JUST VECNOW-TRANSPOSE; SEE EQ.(24) OF M.H. ALEXANDER, "HYBRID QUANTUM
C  SCATTERING ALGORITHMS ..."
      CALL TRNSFM(VECNOW, Z, W, NCH, .FALSE., ISYM )
C
C     IF (IPRINT.GE.20) THEN
C       IF (ITWO.LT.0) WRITE(6,280)
C       IF (ITWO.EQ.0) WRITE(6,290)
C       IF (ITWO.GT.0) WRITE(6,300)
C280    FORMAT('  ** AIRY PROPAGATION - FIRST ENERGY;',
C    :         ' TRANSFORMATION MATRICES NOT WRITTEN')
C290    FORMAT('  ** AIRY PROPAGATION - FIRST ENERGY;',
C    :         ' TRANSFORMATION MATRICES WRITTEN')
C300    FORMAT('  ** AIRY PROPAGATION - SECOND ENERGY;',
C    :         ' TRANSFORMATION MATRICES READ')
C     ENDIF
C
C     IF (IPRINT.GE.20) THEN
C       WRITE(6,305) RSTART, RSTOP, TOLHI, NSTEP
C       WRITE(6,310) SPCMN, SPCMX, POWR
C305    FORMAT('         RSTART =', F10.3, '  RSTOP  =', 1PG11.3,
C    :         '    TOLHI =', 1PE8.1, '  NINTERVAL =', I8)
C310    FORMAT('         DRMIN  =', F10.4, '  DRMAX =', 1PG11.3,
C    :         '    POWER =', 0PF4.1)
      IF (IPRINT.GE.13) THEN
        WRITE(6, 315) SPCMN, SPCMX
315     FORMAT(/'  AIRY.   DRMIN =', 0PF10.4, '   DRMAX =', 1PG11.3$)
      ENDIF
      RSTOP = XF
      RETURN
      END