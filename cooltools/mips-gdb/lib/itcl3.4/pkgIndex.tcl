# Tcl package index file, version 1.0

if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded Itcl 3.4 [list load [file join $dir "itcl34.dll"] Itcl]
