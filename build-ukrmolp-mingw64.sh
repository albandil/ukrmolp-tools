# ---------------------------------------------------------------------------- #
# Build UKRmol+ in MSYS2/MinGW64 on Windows                                    #
# ---------------------------------------------------------------------------- #
# Necessary packages to install first:                                         #
#                                                                              #
#    mingw64/mingw-w64-x86_64-arpack                                           #
#    mingw64/mingw-w64-x86_64-clblast                                          #
#    mingw64/mingw-w64-x86_64-cmake                                            #
#    mingw64/mingw-w64-x86_64-doxygen                                          #
#    mingw64/mingw-w64-x86_64-fc                                               #
#    mingw64/mingw-w64-x86_64-graphviz                                         #
#    mingw64/mingw-w64-x86_64-msmpi                                            #
#    mingw64/mingw-w64-x86_64-ninja                                            #
#    mingw64/mingw-w64-x86_64-openblas                                         #
#    mingw64/mingw-w64-x86_64-opencl-headers                                   #
#    mingw64/mingw-w64-x86_64-scalapack                                        #
#                                                                              #
# Requires installation of Microsoft MPI on the destination machine.           #
# ---------------------------------------------------------------------------- #

SRCDIR=/x/codes
INSTDIR=/x/codes/ukrmolp-release-mingw64
FLAGS="-fdefault-integer-8 -march=x86-64-v3"

# ---------------------------------------------------------------------------- #
# Build double precision with MSMPI                                            #
# ---------------------------------------------------------------------------- #

if [ ! -d $INSTDIR/bin.double ]
then
	mkdir -p $HOME/build-mingw64-double
	pushd    $HOME/build-mingw64-double

	cmake \
		-G Ninja \
		-D BUILD_DOC=ON \
		-D BUILD_SHARED_LIBS=ON \
		-D CMAKE_INSTALL_PREFIX=$INSTDIR \
		-D CMAKE_INSTALL_BINDIR=bin.double \
		-D CMAKE_INSTALL_INCLUDEDIR=include/ukrmolp.double \
		-D CMAKE_INSTALL_LIBDIR=lib.double \
		-D CMAKE_Fortran_FLAGS="$FLAGS -fexternal-blas -DMPI_TYPECLASS_REAL=1_mpiint -DMPI_TYPECLASS_INTEGER=2_mpiint -DMPI_TYPECLASS_COMPLEX=3_mpiint -Dusemapping" \
		-D GBTOlib_Fortran_FLAGS="-Dusempi;-Dsplitreduce" \
		-D ARPACK_LIBRARIES="-larpack" \
		-D CLBLAST_LIBRARIES="-lclblast -lOpenCL" \
		-D SCALAPACK_LIBRARIES="-lscalapack" \
		-D UKRMOL_OUT_DIR=$SRCDIR/ukrmol-out \
		-D WITH_CLBLAST=ON \
		-D WITH_MPI=ON \
		$SRCDIR/ukrmol-in || exit 1

	cmake --build . || exit 1
	cmake --install . || exit 1

	popd
fi

# ---------------------------------------------------------------------------- #
# Build quadruple precision without MSMPI                                      #
# ---------------------------------------------------------------------------- #

if [ ! -d $INSTDIR/bin.quad ]
then
	mkdir -p $HOME/build-mingw64-quad
	pushd    $HOME/build-mingw64-quad

	cmake \
		-G Ninja \
		-D BUILD_DOC=OFF \
		-D BUILD_SHARED_LIBS=ON \
		-D CMAKE_INSTALL_PREFIX=$INSTDIR \
		-D CMAKE_INSTALL_BINDIR=bin.quad \
		-D CMAKE_INSTALL_INCLUDEDIR=include/ukrmolp.quad \
		-D CMAKE_INSTALL_LIBDIR=lib.quad \
		-D CMAKE_Fortran_FLAGS="$FLAGS -Dusequadprec" \
		-D ARPACK_LIBRARIES="-larpack" \
		-D CLBLAST_LIBRARIES="-lclblast -lOpenCL" \
		-D UKRMOL_OUT_DIR=$SRCDIR/ukrmol-out \
		-D WITH_CLBLAST=ON \
		-D WITH_MPI=OFF \
		$SRCDIR/ukrmol-in || exit 1

	cmake --build . || exit 1
	cmake --install . || exit 1

	popd
fi

# ---------------------------------------------------------------------------- #
# Finalize                                                                     #
# ---------------------------------------------------------------------------- #

for lib in \
	OpenCL.dll \
	libarpack.dll \
	libclblast.dll \
	libgcc_s_seh-1.dll \
	libgfortran-5.dll \
	libgomp-1.dll \
	libopenblas.dll \
	libquadmath-0.dll \
	libscalapack.dll \
	libstdc++-6.dll \
	libwinpthread-1.dll
do
	cp -v /mingw64/bin/$lib $INSTDIR/bin.double/
	cp -v /mingw64/bin/$lib $INSTDIR/bin.quad/
done

echo "UKRmol+ Windows distribution
============================

This software package provides the following:

  - UKRmol+ (feature subset: MSMPI*, ScaLAPACK*, Arpack, CLBlast)

UKRmol+ components have the versions:

  - GBTOlib: $(git -C $SRCDIR/ukrmol-in/source/gbtolib describe --tags)
  - UKRmol-in: $(git -C $SRCDIR/ukrmol-in describe --tags)
  - UKRmol-out: $(git -C $SRCDIR/ukrmol-out describe --tags)

Additionally, the package requires an existing installation of Microsoft MPI 10.
This can be easily obtained from official channels:

    https://learn.microsoft.com/en-us/message-passing-interface/microsoft-mpi

The first execution of MPI-based programs may trigger a Windows Firewall warning.
The version of ScaLAPACK used in this distribution uses 4-byte integers only.
Running large calculations in MPI-SCATCI is likely to fail.

(*) Note that the quadruple precision version is compiled without MPI, as MSMPI
    does not support quadruple precision at all. Additionally, the program
    scatci_integrals cannot be used in the MPI mode even in double precision
    (it crashes) due to the inability of GNU Fortran compiler to correctly import
    some MPI parameters (in particular MPI_IN_PLACE) from the MSMPI DLL." > $INSTDIR/README.txt
