! ----------------------------------------------------------------------------- !
! Calculates hydrogen atomic delays for polarization and emission along z-axis  !
! ----------------------------------------------------------------------------- !
! Compile as e.g.:                                                              !
!   gfortran Hrabitt.f90 -o Hrabitt -fopenmp \                                  !
!       -I/path/to/mod/multidip \                                               !
!       /path/to/libmultidip.so                                                 !
! ----------------------------------------------------------------------------- !

program Hrabitt

    use multidip_asy,    only: M2_H1s
    use multidip_params, only: pi, wp

    implicit none

    ! atomic unit of energy (eV)
    real(wp), parameter :: Eh = 27.211_wp

    ! atomic unit of time (as)
    real(wp), parameter :: t0 = 24.1888_wp

    ! IR field frequency (eV)
    real(wp), parameter :: wIR = 1.55_wp

    ! final photoelectron energy (eV)
    real(wp), parameter :: Ef_min = 2._wp
    real(wp), parameter :: Ef_max = 100._wp
    integer,  parameter :: nE = 99

    ! angular integrals
    real(wp), parameter :: int_Y00_n_Y10 = 1/sqrt(3._wp)
    real(wp), parameter :: int_Y20_n_Y10 = sqrt(2._wp/15)

    ! spherical harmonics in z direction
    real(wp), parameter :: Y00z = sqrt(1/(4*pi))
    real(wp), parameter :: Y20z = sqrt(5/(4*pi))

    call H2p_main

contains

    subroutine H2p_main

        implicit none

        integer     :: iE
        real(wp)    :: Ef, kf, kn_p, kn_m, phase_p, phase_m, delay
        complex(wp) :: Msps_p, Msps_m, Mspd_p, Mspd_m, M_p, M_m

        print '(8a25)', 'final energy [eV]', 'delay [as]', 'arg M(XUV+IR)', 'arg M(XUV-IR)', &
                        'Re M(XUV+IR)', 'Im M(XUV+IR)', 'Re M(XUV-IR)', 'IM M(XUV-IR)'

        do ie = 1, nE

            Ef = Ef_min + (ie - 1)*(Ef_max - Ef_min)/(nE - 1)   ! final energy
            kf = sqrt(2*Ef/Eh)                                  ! final momentum
            kn_p = sqrt(2*(Ef - wIR)/Eh)                        ! intermediate XUV+IR momentum
            kn_m = sqrt(2*(Ef + wIR)/Eh)                        ! intermediate XUV-IR momentum

            !$omp parallel sections
            !$omp section
            Msps_p = M2_H1s(1, 1, kn_p, 0, kf)
            !$omp section
            Mspd_p = M2_H1s(1, 1, kn_p, 2, kf)
            !$omp section
            Msps_m = M2_H1s(1, 1, kn_m, 0, kf)
            !$omp section
            Mspd_m = M2_H1s(1, 1, kn_m, 2, kf)
            !$omp end parallel sections

            M_p = Msps_p * int_Y00_n_Y10 * int_Y00_n_Y10 * Y00z  &
                + Mspd_p * int_Y00_n_Y10 * int_Y20_n_Y10 * Y20z
            M_m = Msps_m * int_Y00_n_Y10 * int_Y00_n_Y10 * Y00z  &
                + Mspd_m * int_Y00_n_Y10 * int_Y20_n_Y10 * Y20z

            phase_p = atan2(aimag(M_p), real(M_p))
            phase_m = atan2(aimag(M_m), real(M_m))

            delay = (phase_m - phase_p) / (2*wIR/Eh)

            print '(8e25.15)', Ef, delay*t0, phase_p, phase_m, M_p, M_m

        end do

    end subroutine H2p_main

end program
