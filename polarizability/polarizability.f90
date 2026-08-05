! Copyright 2025
!
!  This program is free software: you can redistribute it and/or modify
!  it under the terms of the GNU General Public License as published by
!  the Free Software Foundation, either version 3 of the License, or
!  (at your option) any later version.
!
!  This program is distributed in the hope that it will be useful,
!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!  GNU General Public License for more details.
!
!  You should have received a copy of the GNU General Public License
!  along with this program. Alternatively, you can also visit
!  <https://www.gnu.org/licenses/>.

!> Calculation of static or dynamic dipole polarizability tensor.
!>
!>    > polarizability <omega> [<unit1> [<unit2> [<unit3>]]]
!>
!> The first parameter is the frequency of the field (possibly zero for static polarizability).
!> Then follow unit numbers of all property files written by CDENPROP for a photoionization run.
!>
program polarizability

    use class_molecular_properties_data, only: molecular_properties_data
    use global_utils,                    only: print_ukrmol_header
    use iso_fortran_env,                 only: real64, output_unit

    implicit none

    type(molecular_properties_data) :: props(3)
    real(real64), allocatable       :: mat(:, :), Emat(:, :)

    character(len=100) :: arg
    integer            :: i, j, u, pset, istate, jstate, l, mq
    real(real64)       :: omega, prop, alpha(-1:1, -1:1)
    real(real64)       :: ang3 = 6.74834

    pset  = 1
    alpha = 0

    call print_ukrmol_header(output_unit)

    print '(/,a,/)', 'Program POLARIZABILITY'

    call get_command_argument(1, arg)
    read (arg, *) omega
    do i = 1, min(3, command_argument_count() - 1)
        call get_command_argument(i + 1, arg)
        read (arg, *) u
        print '(a,i0)', 'Reading properties from unit ', u
        call props(i)%read_properties(u, pset)
    end do

    do i = 1, 3
        if (props(i)%non_zero_properties > 0) then
            allocate (Emat(props(i)%no_states, -1:1), mat(-1:1, props(i)%no_states))
            mat = 0
            do j = 1, props(i)%non_zero_properties
                istate = props(i)%properties_index(1, j)
                jstate = props(i)%properties_index(2, j)
                l      = props(i)%properties_index(3, j)
                mq     = props(i)%properties_index(4, j)
                prop   = props(i)%properties(j)
                if (l == 1) then
                    mat(mq, max(istate, jstate)) = prop
                end if
            end do
            do j = 1, props(i)%no_states
                if (props(i)%energies(j) == props(i)%energies(1)) then
                    Emat(j, :) = 0
                else
                    Emat(j, :) = mat(:, j) / (props(i)%energies(j) - props(i)%energies(1) - omega)
                end if
            end do
            alpha = alpha + matmul(mat, Emat)
            deallocate (mat, Emat)
        end if
    end do

    print '(/,a,/)', 'Cartesian components of alpha (Angstrom^3):'
    do i = 1, 3
        do j = 1, 3
            write (*, '(f10.5)', advance='no') 2*alpha(c2s(i), c2s(j))/ang3
        end do
        print '()'
    end do
    print '(/,a,/)', 'Cartesian components of alpha (atomic units):'
    do i = 1, 3
        do j = 1, 3
            write (*, '(f10.5)', advance='no') 2*alpha(c2s(i), c2s(j))
        end do
        print '()'
    end do
    print '(/,a,/)', 'Average polarisability, Tr alpha/3 (Angstrom^3):'
    print '(f10.5)', 2*(alpha(-1, -1) + alpha(0, 0) + alpha(+1, +1))/3/ang3
    print '(/,a,/)', 'Average polarisability, Tr alpha/3 (atomic units):'
    print '(f10.5,/)', 2*(alpha(-1, -1) + alpha(0, 0) + alpha(+1, +1))/3
    print '(a)', 'Done.'

contains

    ! Return the spherical index (-1 = y, 0 = z, +1 = x) for a given Cartesian index (1 = x, 2 = y, 3 = z).
    integer function c2s(c) result (s)

        integer, intent(in) :: c

        s = mod(c + 1, 3) - 1

    end function c2s

end program

