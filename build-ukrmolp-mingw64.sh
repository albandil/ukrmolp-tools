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
#    mingw64/mingw-w64-x86_64-ninja                                            #
#    mingw64/mingw-w64-x86_64-openblas                                         #
#    mingw64/mingw-w64-x86_64-opencl-headers                                   #
#                                                                              #
# Requires installation of Microsoft MPI on the destination system.            #
# ---------------------------------------------------------------------------- #

SRCDIR=/x/codes
INSTDIR=/x/codes/ukrmolp-release-mingw64

declare -A flags
common_flags="-fdefault-integer-8 -march=x86-64-v3 -fno-signed-zeros -fno-trapping-math -fassociative-math -fstack-arrays"
flags[double]="$common_flags -fexternal-blas -Dusemapping"
flags[quad]="$common_flags -Dusequadprec"

for prec in double quad
do
	mkdir -p $HOME/build-mingw64-$prec
	pushd    $HOME/build-mingw64-$prec

	cmake \
		-G Ninja \
		-D BUILD_DOC=ON \
		-D BUILD_SHARED_LIBS=ON \
		-D CMAKE_INSTALL_PREFIX=$INSTDIR \
		-D CMAKE_INSTALL_BINDIR=bin.$prec \
		-D CMAKE_INSTALL_INCLUDEDIR=include/ukrmolp.$prec \
		-D CMAKE_INSTALL_LIBDIR=lib.$prec \
		-D CMAKE_Fortran_FLAGS="${flags[$prec]}" \
		-D ARPACK_LIBRARIES="-larpack" \
		-D CLBLAST_LIBRARIES="-lclblast -lOpenCL" \
		-D UKRMOL_OUT_DIR=$SRCDIR/ukrmol-out \
		-D WITH_CLBLAST=ON \
		-D WITH_MPI=OFF \
		$SRCDIR/ukrmol-in || exit 1

	cmake --build . || exit 1
	cmake --install . || exit 1

	popd
done

for lib in \
	OpenCL.dll \
	libarpack.dll \
	libclblast.dll \
	libgcc_s_seh-1.dll \
	libgfortran-5.dll \
	libgomp-1.dll \
	libopenblas.dll \
	libquadmath-0.dll \
	libstdc++-6.dll \
	libwinpthread-1.dll
do
	cp -v /mingw64/bin/$lib $INSTDIR/bin.double/
	cp -v /mingw64/bin/$lib $INSTDIR/bin.quad/
done

echo "UKRmol+ Windows portable distribution
=====================================

This software package provides the following:

  - UKRmol+ (feature subset: Arpack, CLBlast)

UKRmol+ components have the versions:

  - GBTOlib: $(git -C $SRCDIR/ukrmol-in/source/gbtolib describe --tags)
  - UKRmol-in: $(git -C $SRCDIR/ukrmol-in describe --tags)
  - UKRmol-out: $(git -C $SRCDIR/ukrmol-out describe --tags)

UKRmol+ is built for the x86-64-v3 (AVX2) instruction set. If you
encounter program failures, your CPU may be too old." > $INSTDIR/README.txt
