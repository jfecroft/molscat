      SUBROUTINE DEGEN9(JJ1,JJ2,DEGFAC)
C  Copyright (C) 2018 J. M. Hutson & C. R. Le Sueur
C  Distributed under the GNU General Public License, version 3
C
      IMPLICIT NONE
      INTEGER JJ1,JJ2
      DOUBLE PRECISION DEGFAC
C
C  DEGEN9 IS CALLED TO OBTAIN THE DEGENERACY FACTOR FOR THE DENOMINATOR
C  OF A CROSS-SECTION CALCULATION; IT DOES NOT MATTER FOR BOUND STATES.
C
      DEGFAC=1.D0
      RETURN

      END
