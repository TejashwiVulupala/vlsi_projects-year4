# GTKWave TCL script to auto-add all signals and zoom

set all_facs [list]
for {set i 0} {$i < [ gtkwave::getNumFacs ] } {incr i} {
    lappend all_facs [gtkwave::getFacName $i]
}

# Add all signals to the viewer
gtkwave::addSignalsFromList $all_facs

# Zoom out slightly to see the transaction timeline
gtkwave::setZoomFactor -3