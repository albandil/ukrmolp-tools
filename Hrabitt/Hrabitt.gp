set encoding utf8
set minussign
set title "Hydrogen RABITT delays" font "Sans,14"
set xlabel "photoelectron energy (eV)"
set ylabel "atomic time delay (as)"
set key bottom right width -8 height 1 box linecolor rgbcolor "light-grey"

plot [0:100] \
    "Hrabitt.out" every ::1 with lines title "Hrabitt", \
    "reference/Dahlstrom2013-Fig5.txt" with lines title "Dahlström et al. (2013) Fig. 5 [p dataset]", \
    "reference/H-Pazourek2015-Fig9.txt" with points pointtype 6 title "Pazourek et al. (2015) Fig. 9 [t_R H(1s) dataset]"
