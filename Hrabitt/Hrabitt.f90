! ----------------------------------------------------------------------------- !
! Calculates hydrogen atomic delays for polarization and emission along z-axis  !
! ----------------------------------------------------------------------------- !
! Compile as e.g.:                                                              !
!   gfortran Hrabitt.f90 -o Hrabitt -fopenmp \                                  !
!       -I/path/to/mod/multidip \                                               !
!       /path/to/libmultidip.so                                                 !
! ----------------------------------------------------------------------------- !
! Usage:                                                                        !
!   ./Hrabitt [--gauge length|velocity] [--order xuv-ir|ir-xuv|both]            !
!                                                                               !
! The order says which of the two photons interacts with the atom first, "both" !
! sums the two time orderings. Only this sum is independent of the gauge.       !
! The default is the length gauge and XUV photon first.                         !
! ----------------------------------------------------------------------------- !

program Hrabitt

    use multidip_asy,     only: M2_H1s
    use multidip_params,  only: imu, pi, wp
    use multidip_special, only: coul_c, cphase

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

    ! energy of the initial state (a.u.)
    real(wp), parameter :: E1s = -0.5_wp

    ! angular integrals
    real(wp), parameter :: int_Y00_n_Y10 = 1/sqrt(3._wp)
    real(wp), parameter :: int_Y20_n_Y10 = 2/sqrt(15._wp)

    ! spherical harmonics in z direction
    real(wp), parameter :: Y00z = sqrt(1/(4*pi))
    real(wp), parameter :: Y20z = sqrt(5/(4*pi))

    ! gauge and time ordering of the photons
    logical :: velocity  = .false.
    logical :: xuv_first = .true.
    logical :: ir_first  = .false.

    call read_options
    call H2p_main

contains

    subroutine read_options

        character(len=64) :: arg, val
        integer           :: iarg

        iarg = 1

        do while (iarg <= command_argument_count())

            call get_command_argument(iarg, arg)
            call get_command_argument(iarg + 1, val)    ! blank if there is none

            select case (arg)

                case ('-g', '--gauge')
                    select case (val)
                        case ('length');    velocity = .false.
                        case ('velocity');  velocity = .true.
                        case default;       call usage('unknown gauge "' // trim(val) // '"')
                    end select
                    iarg = iarg + 2

                case ('-o', '--order')
                    select case (val)
                        case ('xuv-ir');    xuv_first = .true.;   ir_first = .false.
                        case ('ir-xuv');    xuv_first = .false.;  ir_first = .true.
                        case ('both');      xuv_first = .true.;   ir_first = .true.
                        case default;       call usage('unknown order "' // trim(val) // '"')
                    end select
                    iarg = iarg + 2

                case ('-h', '--help')
                    call usage('')

                case default
                    call usage('unknown option "' // trim(arg) // '"')

            end select

        end do

    end subroutine read_options


    subroutine usage (message)

        use, intrinsic :: iso_fortran_env, only: error_unit

        character(len=*), intent(in) :: message

        if (len(message) > 0) write (error_unit, '(a)') 'Error: ' // message
        write (error_unit, '(a)') 'Usage: Hrabitt [--gauge length|velocity] [--order xuv-ir|ir-xuv|both]'

        if (len(message) > 0) stop 1
        stop

    end subroutine usage


    subroutine H2p_main

        implicit none

        integer     :: iE
        real(wp)    :: Ef, w, wXUV_p, wXUV_m, phase_p, phase_m, delay
        complex(wp) :: M_p(nE), M_m(nE)

        w = wIR/Eh

        !$omp parallel do private(Ef, wXUV_p, wXUV_m) schedule(dynamic)
        do ie = 1, nE

            Ef = (Ef_min + (ie - 1)*(Ef_max - Ef_min)/(nE - 1))/Eh  ! final energy
            wXUV_p = Ef - E1s - w                                   ! energy of the XUV photon in the XUV+IR pathway
            wXUV_m = Ef - E1s + w                                   ! energy of the XUV photon in the XUV-IR pathway

            M_p(ie) = 0
            M_m(ie) = 0

            if (xuv_first) then
                M_p(ie) = M_p(ie) + M2(wXUV_p, +w)
                M_m(ie) = M_m(ie) + M2(wXUV_m, -w)
            end if

            if (ir_first) then
                M_p(ie) = M_p(ie) + M2(+w, wXUV_p)
                M_m(ie) = M_m(ie) + M2(-w, wXUV_m)
            end if

        end do

        print '(8a25)', 'final energy [eV]', 'delay [as]', 'arg M(XUV+IR)', 'arg M(XUV-IR)', &
                        'Re M(XUV+IR)', 'Im M(XUV+IR)', 'Re M(XUV-IR)', 'IM M(XUV-IR)'

        do ie = 1, nE

            Ef = Ef_min + (ie - 1)*(Ef_max - Ef_min)/(nE - 1)

            phase_p = atan2(aimag(M_p(ie)), real(M_p(ie)))
            phase_m = atan2(aimag(M_m(ie)), real(M_m(ie)))

            delay = (phase_m - phase_p) / (2*w)

            print '(8e25.15)', Ef, delay*t0, phase_p, phase_m, M_p(ie), M_m(ie)

        end do

    end subroutine H2p_main


    ! Two-photon ionization amplitude of H(1s) for a given time ordering of the photons: The atom first exchanges
    ! the energy w1 with the field and then the energy w2 (a.u.; positive for absorption, negative for emission).
    !
    ! In the length gauge this is <f|z G(E1s + w1) z|i>. In the velocity gauge it is <f|d/dz G(E1s + w1) d/dz|i>/(w1 w2),
    ! where the denominator comes from the amplitudes of the vector potential, so that both forms multiply the same
    ! electric field amplitudes. As d/dz = [z,H], the two differ only by a one-photon term,
    !
    !     M_vel(w1,w2) = M_len(w1,w2) + (w1 - w2)/(2 w1 w2) <f|z^2|i> ,
    !
    ! which cancels in the sum over both time orderings.

    complex(wp) function M2 (w1, w2) result (M)

        real(wp), intent(in) :: w1, w2

        real(wp)    :: kf
        complex(wp) :: kn, Msps, Mspd

        kn = sqrt(cmplx(2*(E1s + w1), 0, wp))   ! intermediate momentum (imaginary below the ionization threshold)
        kf = sqrt(2*(E1s + w1 + w2))            ! final momentum

        Msps = M2_H1s(1, 1, kn, 0, kf)
        Mspd = M2_H1s(1, 1, kn, 2, kf)

        if (velocity) then
            Msps = Msps + (w1 - w2)/(2*w1*w2) * M1r2_H1s(0, kf)
            Mspd = Mspd + (w1 - w2)/(2*w1*w2) * M1r2_H1s(2, kf)
        end if

        M = Msps * int_Y00_n_Y10 * int_Y00_n_Y10 * Y00z  &
          + Mspd * int_Y00_n_Y10 * int_Y20_n_Y10 * Y20z

    end function M2


    ! Partial amplitude of the one-photon transition from H(1s) to the s-wave or d-wave by the operator r^2,
    !
    !     i^(-l) exp(i sigma_l) int F_l(k,r) r^2 P_10(r) dr ,    P_10(r) = 2 r exp(-r) .
    !
    ! The radial integrals follow by differentiation of int exp(-x r) r^l F_l(k,r) dr, which is equal to
    ! (2l+1)! C_l k^(l+1) (x^2 + k^2)^(-l-1) exp(-2/k atan(k/x)), with respect to x.

    complex(wp) function M1r2_H1s (l, k) result (M1)

        integer,  intent(in) :: l
        real(wp), intent(in) :: k

        real(wp) :: Cl, R

        Cl = coul_c(l, -1/k)

        select case (l)
            case (0);       R = -16*Cl*k   /(1 + k*k)**3
            case (2);       R = 960*Cl*k**3/(1 + k*k)**4
            case default;   error stop 'M1r2_H1s: Only s-wave and d-wave are implemented.'
        end select

        M1 = imu**(-l) * exp(imu*cphase(1._wp, l, k)) * R * exp(-2/k * atan(k))

    end function M1r2_H1s

end program
