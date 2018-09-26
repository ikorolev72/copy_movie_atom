#						Movie atom copy


##  What is it?
##  -----------
This script copy movie atoms ( `moov`, `ftyp`, `uuid` etc) from video file 'in' to file 'out'. Exclude atom `mdat` with video/audio streams. For atom `mdat` script copy only 8 bytes of header and size.
This can be usefull if your video file have broken header ( eg continius copy from video camera ).

##  The Latest Version

	version 2.0 2018.09.26

##  What's new

## How to run
if you have installed perl 
```
        perl fix_moov_atom.pl --in=IN --out=OUT [--nobackup][ --help ]
```
or use compled version
```
Usage:
        fix_moov_atom.exe --in=IN --out=OUT [--nobackup][ --help ]
Where:
        --in=IN - Original source file
        --out=OUT - Target file
        --nobackup - Warning ! Do not make the backup copy of target file, directly fix all in target file
        --debug - show debug information
        --help - this help
Sample: C:\tools\fix_moov_atom.exe --in=1.mp4 --out=2.mp4 --nobackup
```
## Download
Compiled version for Windows ( 64bit) available .... soon



##  Bugs
##  ------------



  Licensing
  ---------
	GNU

  Contacts
  --------

     o korolev-ia [at] yandex.ru
     o http://www.unixpin.com

