      SUBROUTINE YINIT(Y,W,VL,IV,P,CENT,EINT,DIAG,EVAL,EVECS,
     1                 N,MXLAM,NPOTL,
     2                 ERED,R,RMLMDA,ZOUT,
     3                 IPRINT)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
      IMPLICIT NONE
C
C  THIS SUBROUTINE INITIALISES THE LOG-DERIVATIVE MATRIX
C  WRITTEN BY CRLS JULY 2016
C  SIMPLIFIED BY JMH NOV 2018
C
C  ON ENTRY:
C  VL,IV,P,CENT,EINT   } ARE USED TO EVALUATE THE W MATRIX
C  R,RMLMDA,MXLAM,NPOTL}
C  ISCRU  CONTAINS THE STREAM NUMBER FOR THE SCRATCH FILE (0 IF UNUSED)
C  ZOUT   INDICATES IF DIRECTION OF PROPAGATION IS OUTWARDS
C  IREAD  INDICATES WHETHER W MATRIX IS TO BE READ FROM ISCRU
C  IWRITE INDICATES WHETHER W MATRIX IS TO BE WRITTEN TO ISCRU
C
C  ON EXIT:
C  Y      CONTAINS THE LOG-DERIVATIVE MATRIX SPECIFIED BY THE
C         BOUNDARY CONDITIONS
      DOUBLE PRECISION, INTENT(OUT):: Y(N,N)
      DOUBLE PRECISION, INTENT(IN):: VL(1),P(1),ERED,R,EINT(N),
     &                               RMLMDA,CENT(N)
      LOGICAL, INTENT(IN):: ZOUT
      INTEGER, INTENT(IN):: N,IV(1),MXLAM,NPOTL,IPRINT
C  THE FOLLOWING ARRAYS ARE USED AS WORKSPACE AND VALUES RETURNED
C  ARE NOT USED
      DOUBLE PRECISION, INTENT(OUT):: W(N,N),DIAG(N),EVAL(N),EVECS(N,N)
C
C  COMMON BLOCK FOR CONTROL OF PROPAGATION BOUNDARY CONDITIONS
      COMMON /BCCTRL/ BCYCMN,BCYCMX,BCYOMN,BCYOMX,ADIAMN,ADIAMX,
     1                WKBMN,WKBMX
      LOGICAL ADIAMN,ADIAMX,WKBMN,WKBMX
      DOUBLE PRECISION BCYCMN,BCYCMX,BCYOMN,BCYOMX

C
C  COMMON BLOCK FOR CONTROL OF USE OF PROPAGATION SCRATCH FILE
      LOGICAL IREAD,IWRITE
      INTEGER ISCRU
      DOUBLE PRECISION ESHIFT
      COMMON /PRPSCR/ ESHIFT,ISCRU,IREAD,IWRITE
C
C  COMMON BLOCK FOR CONTROL OF PROPAGATION SEGMENTS
      COMMON /RADIAL/ RMNINT,RMXINT,RMID,RMATCH,DRS,DRL,STEPS,STEPL,
     1                POWRS,POWRL,TOLHIS,TOLHIL,CAYS,CAYL,UNSET,
     2                IPROPS,IPROPL,NSEG
      DOUBLE PRECISION RMNINT,RMXINT,RMID,RMATCH,DRS,DRL,STEPS,STEPL,
     1                 POWRS,POWRL,TOLHIS,TOLHIL,CAYS,CAYL,UNSET
      INTEGER IPROPS,IPROPL,NSEG


C  INTERNAL VARIABLES
      INTEGER I,J,NOPEN,IFAIL
      LOGICAL ADIAB
      DOUBLE PRECISION WREF,WVAL
      DOUBLE PRECISION, PARAMETER:: ZERTOL=1D-10

c  ADIAB MEANS INITIALISE IN DIABATIC BASIS
      ADIAB=(ZOUT .AND. ADIAMN) .OR. (.NOT.ZOUT .AND. ADIAMX)

c  The IREAD/IWRITE logic will not work unless ESHIFT is passed properly.
c  I've disabled it for now.
c     IF (IREAD) THEN
c       READ(ISCRU) W
c       IF (ADIAB) THEN
c         READ(ISCRU) EVAL,EVECS
c  If we revive the IREAD/IWRITE capability, 
c  I think this shift needs to be inside the read section
c         DO I=1,N
c           EVAL(I)=EVAL(I)-ESHIFT
c         ENDDO
c       ELSE
c         DO I=1,N
c           W(I,I)=W(I,I)-ESHIFT
c         ENDDO
c     ELSE
        CALL WAVMAT(W,N,R,P,VL,IV,ERED,EINT,CENT,RMLMDA,DIAG,
     1              MXLAM,NPOTL,IPRINT)
c  Would need to write W without condition on ADIAMN and ADIAMX
c       IF (IWRITE) WRITE(ISCRU) W,EVAL
C
C  FOR INITIALISATION IN ADIABATIC BASIS, DIAGONALISE W
C
        IF (ADIAB) THEN
          CALL DIAGVC(W,N,N,EVAL,EVECS)
c         IF (IWRITE) WRITE(ISCRU) EVAL,EVECS
        ENDIF
c     ENDIF
C
      DO J=1,N
        DO I=1,N
          Y(I,J)=0.D0
        ENDDO
      ENDDO
C
      NOPEN=0
      DO I=1,N
C  CHOOSE THE VALUE (EIGENVALUE OR DIAGONAL ELEMENT OF W) TO USE FOR Y
        IF (ADIAB) THEN
          WVAL=EVAL(I)
        ELSE
          WVAL=W(I,I)
        ENDIF
        IF (WVAL.GT.0.D0) THEN
C  CLOSED CHANNEL
          IF (ZOUT) THEN
            IF (WKBMN) THEN
              Y(I,I)=SQRT(ABS(WVAL))
            ELSE
              Y(I,I)=BCYCMN
            ENDIF
          ELSE
            IF (WKBMX) THEN
              Y(I,I)=-SQRT(ABS(WVAL))
            ELSE
              Y(I,I)=BCYCMX
            ENDIF
          ENDIF
        ELSE
C  OPEN CHANNEL
          IF (ZOUT) THEN
            Y(I,I)=BCYOMN
          ELSE
            Y(I,I)=BCYOMX
          ENDIF
          IF (ABS(WVAL).GT.ZERTOL) NOPEN=NOPEN+1
        ENDIF
      ENDDO
C
      IF (NOPEN.GT.0) THEN
        IF (ZOUT) THEN
          IF (IPRINT.GE.3) WRITE(6,601) NOPEN,'RMIN'
        ELSEIF (IPRINT.GE.8) THEN
          WRITE(6,601) NOPEN,'RMAX'
  601     FORMAT('  **** WARNING:',I5,' OPEN CHANNELS DETECTED AT ',A4)
        ENDIF
      ENDIF
C
C  ALL PROPAGATORS NEED Y IN THE PRIMITIVE BASIS, SO NEED TO ROTATE
C  IT IF IT WAS OBTAINED IN THE ADIABATIC BASIS
C  Y_PROP=EVECS*Y_LOCAL*EVECS^T
C
      IF (ADIAB) THEN
        CALL TRNSP(EVECS,N)
        CALL TRNSFM(EVECS,Y,W,N,.FALSE.,.TRUE.)
      ENDIF
C
      IF (IPRINT.GE.20) THEN
        CALL MATPRN(6,Y,N,N,N,2,Y,' INITIAL Y MATRIX',1)
      ENDIF

      RETURN
      END
