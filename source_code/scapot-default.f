      SUBROUTINE SCAPOT(P,MXLAM,RMLMDA)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
C  WRITTEN ON 26-10-2018 BY CRLS
C
C  THIS SUBROUTINE SCALES ALL THE POTENTIAL COEFFICIENTS P BY THE
C  SCALING FACTOR SCALAM, AND THEN USES RMLMDA TO CONVERT THEM INTO
C  INTERNAL UNITS (THIS CODE WAS ORIGINALLY IN WAVMAT)
      IMPLICIT NONE

      INTEGER,          INTENT(IN)    :: MXLAM
      DOUBLE PRECISION, INTENT(IN)    :: RMLMDA
      DOUBLE PRECISION, INTENT(INOUT) :: P(MXLAM)

      DOUBLE PRECISION SCALAM
      COMMON /SCALE / SCALAM

      INTEGER I

      DO I=1,MXLAM
        P(I)=P(I)*SCALAM
        P(I)=P(I)*RMLMDA
      ENDDO

      RETURN
      END
