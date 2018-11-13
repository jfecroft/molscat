      SUBROUTINE CPL4(N,MXLAM,LAM,NSTATE,JSTATE,JSINDX,L,JTOT,ATAU,
     1                VL,IPRINT,LFIRST)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  THIS SUBROUTINE CALCULATES COUPLING MATRIX ELEMENTS FOR ITYPE=4 (CPL4)
C  & ITYPE=24 (CPL24)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      SAVE IFIRST,NOMEM,NL12,IXMX,ISTART
C  SPECIFICATIONS FOR PARAMETER LIST
      INTEGER JSINDX(N),L(N),LAM(*),JSTATE(2)
      INTEGER IPRINT
      DIMENSION ATAU(*),VL(*)
      LOGICAL LFIRST
C
      INTEGER P1,Q1,P2,P
      LOGICAL LODD,NOMEM,L20
C
C  DYNAMIC STORAGE COMMON BLOCK ...
      COMMON /MEMORY/ MX,IXNEXT,NIPR,IDUMMY,X(1)
C
      COMMON /VLSAVE/ IVLU
C
      DATA PI /3.141592653589793D0/
      DATA EPS /1.D-8/, Z0 /0.D0/
C
C  STATEMENT FUNCTIONS ...
      F(NN) = DBLE(NN+NN+1)
      LODD(I) = I-2*(I/2).NE.0
C
      L20=.FALSE.
      IF (LFIRST) THEN
        IFIRST=-1
        LFIRST=.FALSE.
        NOMEM=.FALSE.
      ENDIF
      IF (IFIRST.GT.-1) GOTO 5500

      IF (NOMEM) GOTO 5900

      NL12=NSTATE*(NSTATE+1)/2
      IXMX=NL12*MXLAM
      ISTART=MX+1
      NAVAIL=ISTART-IXNEXT
      IF (IXMX.LE.NAVAIL) GOTO 5100

      IF (IPRINT.GE.3) WRITE(6,694) IXMX,NAVAIL
  694 FORMAT(/'  CPL4 (JUL 93).   UNABLE TO STORE JTOT-INDEPENDENT PART'
     1       /'                   REQUIRED AND AVAILABLE STORAGE =',2I9)
      NOMEM=.TRUE.
      GOTO 5900

 5100 IX=0
      DO 5200 LL=1,MXLAM
        P1 = LAM(4*LL-3)
        Q1 = LAM(4*LL-2)
        P2 = LAM(4*LL-1)
        P  = LAM(4*LL)
        XP1 = P1
        XQ1 = Q1
        DO 5201 IC=1,NSTATE
          JC  = JSTATE(IC)
          J1C = JSTATE(IC + 2*NSTATE)
          J2C = JSTATE(IC +   NSTATE)
          XJC = JC
          XJ1C = J1C
          XJ2C = J2C
          ISTC = JSTATE(IC + 5*NSTATE)
          NKC  = JSTATE(IC + 6*NSTATE)
        DO 5201 IR=1,IC
          IX=IX+1
          JR=   JSTATE(IR)
          J1R = JSTATE(IR + 2*NSTATE)
          J2R = JSTATE(IR +   NSTATE)
          XJR=JR
          XJ1R = J1R
          XJ2R = J2R
          ISTR = JSTATE(IR + 5*NSTATE)
          NKR  = JSTATE(IR + 6*NSTATE)
          XCPL=Z0
          KKC=-J1C
          DO 5300 KC=1,NKC
C  SKIP IMMEDIATELY IF COEFFICIENT IS SMALL.
            IF (ABS(ATAU(ISTC+KC)).LE.EPS) GOTO 5300

            XKC=KKC
            KKR=-J1R
            DO 5400 KR=1,NKR
C  SKIP IMMEDIATELY IF COEFFICIENT IS SMALL.
              IF (ABS(ATAU(ISTR+KR)).LE.EPS) GOTO 5400

              XKR=KKR
              AF=ATAU(ISTR+KR)*ATAU(ISTC+KC)
              IF (LODD(KKR)) AF=-AF
              IF (KKR-KKC.NE.Q1) GOTO 5401

              XCPL=XCPL+AF*THRJ(XJ1R,XP1,XJ1C,-XKR,XQ1,XKC)
              IF (Q1.EQ.0) GOTO 5400

 5401         IF (KKC-KKR.NE.Q1) GOTO 5400

C  ADJUST FOR (-1)**MU IN POTENTIAL. . .
              AF=AF*PARSGN(P1+Q1+P2+P)
              XCPL=XCPL+AF*THRJ(XJ1R,XP1,XJ1C,-XKR,-XQ1,XKC)
 5400         KKR=KKR+1
 5300       KKC=KKC+1
C  NOW GET 'CONSTANT FACTORS'
          XFCT=PARSGN(JR-J1C+J2C)
     1         *SQRT(F(J2R)*F(J2C)*F(P)*F(P2)*F(JR)*F(JC)*F(J1C)*F(J1R))
     2         *THREEJ(J2R,P2,J2C)*XNINEJ(JC,JR,P,J1C,J1R,P1,J2C,J2R,P2)
     3         /4.D0/PI
 5201     X(ISTART-IX)=XCPL*XFCT
 5200 CONTINUE

      IF (IPRINT.GE.4) WRITE(6,695) IXMX
  695 FORMAT(/'  CPL4 (JUL 93).   JTOT-INDEPENDENT PARTS OF COUPLING',
     1        ' MATRIX STORED.'/
     2        '                   REQUIRED STORAGE =',I8)
C  RESET MX, IFIRST TO REFLECT STORED VALUES
      MX=MX-IXMX
      IFIRST=0
C
C  NOW GET COUPLING MATRIX ELEMENTS FROM STORED PARTS
 5500 PJT=PARSGN(JTOT)
      IF (IVLU.GT.0) REWIND IVLU
      NZERO=0
      DO 5600 LL=1,MXLAM
        P1 = LAM(4*LL-3)
        Q1 = LAM(4*LL-2)
        P2 = LAM(4*LL-1)
        P  = LAM(4*LL)
C
        PPP = PARSGN(P)
        IX1=(LL-1)*NL12
        NNZ=0
        IF (IVLU.EQ.0) THEN
          IX=LL
        ELSE
          IX=1
        ENDIF
C
        DO 5700 IC=1,N
          INJ12P = JSINDX(IC)
          JC=JSTATE(INJ12P)
          LC=L(IC)
C
        DO 5700 IR=1,IC
          INJ12=JSINDX(IR)
          JR=JSTATE(INJ12)
          LR=L(IR)
C
          XFACT = PJT*PPP*THREEJ(LR,P,LC)*SIXJ(LR,JR,LC,JC,JTOT,P)
     1               *SQRT(F(LR)*F(LC))
          IF (INJ12.GE.INJ12P) THEN
            IX2=INJ12*(INJ12-1)/2+INJ12P
          ELSE
            IX2=INJ12P*(INJ12P-1)/2+INJ12
          ENDIF
          INDX=IX1+IX2
C
          IF (X(ISTART-INDX).EQ.0.D0) THEN
            VL(IX) = 0.D0
          ELSE
            VL(IX)=XFACT*X(ISTART-INDX)
          ENDIF
          IF (VL(IX).NE.0.D0) NNZ=NNZ+1
          IF (IVLU.EQ.0) THEN
            IX=IX+MXLAM
          ELSE
            IX=IX+1
          ENDIF
 5700   CONTINUE
        IF (NNZ.EQ.0) THEN
          NZERO=NZERO+1
          IF (IPRINT.GE.14) WRITE(6,697) P1,Q1,P2,P
        ENDIF
        IF (IVLU.GT.0) WRITE(IVLU) (VL(I),I=1,N*(N+1)/2)
 5600 CONTINUE

      IF (NZERO.GT.0 .AND. IPRINT.GE.10 .AND. IPRINT.LT.14)
     1  WRITE(6,620) 'JTOT',JTOT,NZERO
  620 FORMAT('  * * * NOTE.  FOR ',A,' =',I4,',  ALL COUPLING ',
     1       'COEFFICIENTS ARE 0.0 FOR',I5,' POTENTIAL EXPANSION TERMS')

      RETURN
C
C  IF WE CANNOT STORE PARTIAL COUPLING MATRIX, RECALCULATE.
 5900 IGO1=3001
      IGO2=3011
      GOTO 3000
C----------------------------------------------------------------------------
      ENTRY CPL24(N,MXLAM,LAM,NSTATE,JSTATE,JSINDX,MVAL,ATAU,
     1            VL,IPRINT,LFIRST)
      L20=.TRUE.
C
C  IF LFIRST IS TRUE (FIRST CALL), DO SOME INITIALIZATION
      IF (LFIRST) THEN
        IFIRST=-1
        LFIRST=.FALSE.
        NOMEM=.FALSE.
      ENDIF
C
      IF (IFIRST.GT.-1) GOTO 4500

C  FIRST TIME THROUGH SET UP SOME STORAGE POINTERS
      NL12=NSTATE*(NSTATE+1)/2
      IXMX=NL12*MXLAM
      ISTART=MX+1
C
 4500 MVABS=IABS(MVAL)
C  SEE IF VALUES ARE STORED FOR THIS HIGH AN MVALUE
C  IF NOT, TRY TO STORE THEM IN XCPL().
      IF (MVABS.LE.IFIRST .OR. NOMEM) GOTO 4900

      MV=IFIRST+1
C  FIRST CHECK THAT WE STILL HAVE A CONTINUOUS BLOCK OF HI MEMORY.
 4600 IF (MX.EQ.ISTART-(IFIRST+1)*IXMX-1) GOTO 4610

      IF (IPRINT.GE.1) WRITE(6,642) MV,ISTART-1,MX,IXMX*(IFIRST+1)
  642 FORMAT(/' CPL24 (JUL 93).  HIGH MEMORY FRAGMENTED.  CANNOT',
     1       ' STORE COUPLING COEFFS FOR MVAL=',I3/ 19X,'ORIGINAL '
     2       'MINUS CURRENT MEMORY LIMITS .NE. NO. USED =',3I12)
      NOMEM=.TRUE.
      GOTO 4900

C  TEST FOR AVAILABLE STORAGE; NEED IXMX FOR THIS MVAL
 4610 NAVAIL=MX-IXNEXT+1
      IF (IXMX.LE.NAVAIL) GOTO 4601

      IF (IPRINT.GE.3) WRITE(6,692) MV,IXMX,NAVAIL
  692 FORMAT(/' CPL24 (JUL 93).   UNABLE TO STORE 3-J VALUES FOR ',
     1       'MVAL=',I3
     2       /'                   REQUIRED AND AVAILABLE STORAGE =',2I9)
C  SET NOMEM TO REFLECT INABILITY TO ADD MORE M-VALUES
      NOMEM=.TRUE.
      GOTO 4900
C
C  REDUCE 'TOP OF MEMORY' AND STORE COUPLING VALUES FOR THIS MVAL
 4601 MX=MX-IXMX
C  START INDEX AFTER M-BLOCKS ALREADY STORED (STARTING WITH MV=0)
      IX=MV*IXMX
      DO 4200 LL=1,MXLAM
        P1 = LAM(4*LL-3)
        Q1 = LAM(4*LL-2)
        P2 = LAM(4*LL-1)
        P =  LAM(4*LL)
        DO 4201 IC=1,NSTATE
          JC  = JSTATE(IC)
          J1C = JSTATE(IC+2*NSTATE)
          J2C = JSTATE(IC+  NSTATE)
          ISTC= JSTATE(IC+5*NSTATE)
          NKC = JSTATE(IC+6*NSTATE)
        DO 4201 IR=1,IC
          JR  = JSTATE(IR)
          J1R = JSTATE(IR+2*NSTATE)
          J2R = JSTATE(IR+  NSTATE)
          ISTR= JSTATE(IR+5*NSTATE)
          NKR = JSTATE(IR+6*NSTATE)
          IX=IX+1
          XCPL=Z0
          KKC=-J1C
          DO 4300 KC=1,NKC
C  SKIP IMMEDIATELY IF COEFFICIENT IS SMALL.
            IF (ABS(ATAU(ISTC+KC)).LE.EPS) GOTO 4300

            KKR=-J1R
            DO 4400 KR=1,NKR
C  SKIP IMMEDIATELY IF COEFFICIENT IS SMALL.
              IF (ABS(ATAU(ISTR+KR)).LE.EPS) GOTO 4400

              AF=ATAU(ISTR+KR)*ATAU(ISTC+KC)
              IF (KKR-KKC.NE.Q1) GOTO 4401

              XCPL=XCPL+AF*RSYMTP(J1R,KKR,J2R,J1C,KKC,J2C,
     1                            JR,JC,MVAL,P1,Q1,P2,P)
              IF (Q1.EQ.0) GOTO 4400
 4401         IF (KKC-KKR.NE.Q1) GOTO 4400

C  ADJUST FOR (-1)**MU IN POTENTIAL. . .
              IF (LODD(P1+Q1+P2+P)) AF = -AF
              XCPL=XCPL+AF*RSYMTP(J1R,KKR,J2R,J1C,KKC,J2C,
     1                            JR,JC,MVAL,P1,-Q1,P2,P)
 4400         KKR=KKR+1
 4300       KKC=KKC+1
 4201     X(ISTART-IX)=XCPL
 4200 CONTINUE

      IF (IPRINT.GE.4) WRITE(6,693) MV,IXMX,NAVAIL
  693 FORMAT(/' CPL24 (JUL 93).  3J VALUES STORED FOR MVALUE =',I3,
     1       /,'                  REQUIRED AND AVAILABLE STORAGE =',2I9)
      IFIRST = MV
C  SEE IF CURRENT MVALUE REQUIRES MORE STORED M-VALUES.
      MV=MV+1
      IF (MV.LE.MVABS) GOTO 4600
C
 4900 IF (MVABS.GT.IFIRST) GOTO 4800

C  MVABS.LE.IFIRST.  COEFFS STORED.  FILL VL() FROM XCPL
      IXM=MVABS*IXMX
      IF (IVLU.GT.0) REWIND IVLU
      NZERO=0
      DO 4513 LL=1,MXLAM
        P1 = LAM(4*LL-3)
        Q1 = LAM(4*LL-2)
        P2 = LAM(4*LL-1)
        P  = LAM(4*LL)
        NNZ=0
        IF (IVLU.EQ.0) THEN
          IX=LL
        ELSE
          IX=1
        ENDIF
        DO 4503 ICOL=1,N
          I1=JSINDX(ICOL)
          JC=JSTATE(I1)
        DO 4503 IROW=1,ICOL
          I2=JSINDX(IROW)
          JR=JSTATE(I2)
          IF (I1.GT.I2) THEN
            IX12=I1*(I1-1)/2+I2
          ELSE
            IX12=I2*(I2-1)/2+I1
          ENDIF
          IXX=IXM+(LL-1)*NL12+IX12
          VL(IX)=X(ISTART-IXX)
C  WE HAVE STORED COUPLING FOR POSITIVE MVALUES; CORRECT IF NECESSARY
C  FOR PARITY OF THRJ(JR, P ,JC, MVAL, 0, -MVAL)
          IF (MVAL.LT.0 .AND. LODD(JC+JR+P)) VL(IX)=-VL(IX)
          IF (VL(IX).NE.Z0) NNZ=NNZ+1
          IF (IVLU.EQ.0) THEN
            IX=IX+MXLAM
          ELSE
            IX=IX+1
          ENDIF
 4503   CONTINUE
        IF (NNZ.LE.0) THEN
          NZERO=NZERO+1
          IF (IPRINT.GE.14) WRITE(6,612) 'MVAL',MVAL,LL
        ENDIF
  612   FORMAT('  * * * NOTE.  FOR ',A,' =',I4,',  ALL COUPLING '
     1         'COEFFICIENTS ARE 0.0 FOR EXPANSION TERM',I4)
        IF (IVLU.GT.0) WRITE(IVLU) (VL(I),I=1,N*(N+1)/2)
 4513 CONTINUE

      IF (NZERO.GT.0 .AND. IPRINT.GE.10 .AND. IPRINT.LT.14)
     1  WRITE(6,620) 'MVAL',MVAL,NZERO

      RETURN
C
C  MV.GT.IFIRST ==> VALUES NOT STORED.  CALCULATE THEM VIA OLD CODE
 4800 IGO1=3002
      IGO2=3022
      GOTO 3000
C
C  -------------------- OLD CODE REJOINS HERE ---------------------
C
 3000 IF (IVLU.GT.0) REWIND IVLU
C
C  ----- LOOP OVER RADIAL SURFACES -----
C
      NZERO=0
      DO 3100 LL=1,MXLAM
        P1 = LAM(4*LL-3)
        Q1 = LAM(4*LL-2)
        P2 = LAM(4*LL-1)
        P = LAM(4*LL)
        NNZ=0
        IF (IVLU.EQ.0) THEN
          IX=LL
        ELSE
          IX=1
        ENDIF
C
        DO 3200 IC=1,N
          JC   = JSTATE(JSINDX(IC)         )
          J1C  = JSTATE(JSINDX(IC) + 2*NSTATE)
          J2C  = JSTATE(JSINDX(IC) +   NSTATE)
          ISTC = JSTATE(JSINDX(IC) + 5*NSTATE)
          NKC  = JSTATE(JSINDX(IC) + 6*NSTATE)
C
        DO 3200 IR=1,IC
          JR   = JSTATE(JSINDX(IR)         )
          J1R  = JSTATE(JSINDX(IR) + 2*NSTATE)
          J2R  = JSTATE(JSINDX(IR) +   NSTATE)
          ISTR = JSTATE(JSINDX(IR) + 5*NSTATE)
          NKR  = JSTATE(JSINDX(IR) + 6*NSTATE)
C
          VL(IX)=0.D0
          KKC=-J1C
C
C ----- LOOP OVER EXPANSION COEFFICIENTS. -----
C ----- SKIP IMMEDIATELY IF COEFFICIENT IS SMALL. -----
C
          DO 3300 KC=1,NKC
            IF (ABS(ATAU(ISTC+KC)).LE.EPS) GOTO 3300
            KKR=-J1R
C
            DO 3400 KR=1,NKR
              IF (ABS(ATAU(ISTR+KR)).LE.EPS) GOTO 3400
              AF=ATAU(ISTR+KR)*ATAU(ISTC+KC)
              IF (KKR-KKC.NE.Q1) GOTO 3500
              IF (IGO1.EQ.3001) THEN
                VL(IX)=VL(IX)+AF
     1                   *QSYMTP(J1R,KKR,J1C,KKC,J2R,J2C,L(IR),L(IC),
     2                           JR,JC,JTOT,P1,Q1,P2,P)
              ELSEIF (IGO1.EQ.3002) THEN
                VL(IX)=VL(IX)+AF*RSYMTP(J1R,KKR,J2R,J1C,KKC,J2C,
     1                                  JR,JC,MVAL,P1,Q1,P2,P)
              ENDIF
              IF (Q1.EQ.0) GOTO 3400
 3500         IF (KKC-KKR.NE.Q1) GOTO 3400
              AF = AF*PARSGN(P1+P2+P+Q1)
              IF (IGO2.EQ.3011) THEN
                VL(IX)=VL(IX)+AF
     1                    *QSYMTP(J1R,KKR,J1C,KKC,J2R,J2C,L(IR),L(IC),
     2                            JR,JC,JTOT,P1,-Q1,P2,P)
              ELSEIF (IGO2.EQ.3022) THEN
                VL(IX)=VL(IX)+AF*RSYMTP(J1R,KKR,J2R,J1C,KKC,J2C,
     1                                  JR,JC,MVAL,P1,-Q1,P2,P)
              ENDIF
 3400         KKR=KKR+1
C
 3300       KKC=KKC+1
C
          IF (VL(IX).NE.0.D0) NNZ=NNZ+1
          IF (IVLU.EQ.0) THEN
            IX = IX + MXLAM
          ELSE
            IX = IX + 1
          ENDIF
 3200   CONTINUE
        IF (NNZ.EQ.0) THEN
          NZERO=NZERO+1
          IF (IPRINT.GE.14) WRITE(6,697) P1,Q1,P2,P
        ENDIF
  697   FORMAT('  * * *  NOTE.  ALL COUPLING COEFFICIENTS ARE ZERO ',
     1         'FOR P1, Q1, P2, P = ', 4I4)
 3100 CONTINUE

      IF (NZERO.GT.0 .AND. IPRINT.GE.10 .AND. IPRINT.LT.14) THEN
        IF (L20) WRITE(6,620) 'MVAL',MVAL,NZERO
        IF (.NOT.L20) WRITE(6,620) 'JTOT',JTOT,NZERO
      ENDIF

      RETURN
      END
