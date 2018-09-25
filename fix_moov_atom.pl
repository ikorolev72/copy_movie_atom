#!perl
# korolev-ia@yandex.ru

use Getopt::Long;
use File::Copy;
#use Data::Dumper;



my $version="1.1 2018.09.23";
my $interactive=0;

my $in='';
my $out='';
my $begin_bytes=255;
my $end_bytes=100000;
my $help=0;
my $nobackup=0;


GetOptions (
        'in=s' => \$in,
        'out=s' => \$out,
        'begin_bytes=n' => \$begin_bytes,
        'end_bytes=n' => \$end_bytes,
        'nobackup' => \$nobackup,
        "help|h|?"  => \$help ) or show_help();

show_help( "")  if( $help );
show_help( "Need both IN and Out files" ) if( !$in || !$out );
show_help( "Looks like files $in or $out do not exists" ) if( ! -f $in || ! -f $out );



my $begin_data='';
my $end_data='';



open( IN, $in ) || die( "Cannot open file $in: $!");
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev, $in_size, $atime,$mtime,$ctime,$blksize,$blocks) = stat(IN);
binmode( IN );



if( ! read( IN, $begin_data, $begin_bytes )) {
	die("Cannot read data from file $in");
}

# read data from enf of file
if( ! seek ( IN, -$end_bytes, 2 ) ) {
	die("Cannot seek in file $in");
} 

if( ! read( IN, $end_data, $end_bytes )) {
	die("Cannot read data from file $in");
}

close(IN);


### do BACKUP of target file
if( !$nobackup ) {
	my $backup_file="$out.".time();
	if( ! copy($out, $backup_file ) ) {
		die( "Backup copy file $out to $backup_file failed : $!");
	} 
}


open( OUT, '+<', $out )|| die( "Cannot open file $out: $!");
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,	$out_size ,$atime,$mtime,$ctime,$blksize,$blocks) = stat(OUT);
binmode( OUT );



if( ! seek ( OUT, 0, 0 ) ) {
	die("Cannot seek in file $out");
} 
if( ! print OUT $begin_data ) {
	die("Cannot write data to file $out");
}


if( $in_size!=$out_size ) {
	print STDERR "Size of file IN is $in_size, but file size of file OUT is $out_size. Cannot correctly fix bytes in the end of file OUT\n";
	# increase file to required size
	if( ! seek ( OUT, 0, 2 )) {
		die("Cannot seek in file $out");
	} 
	print OUT 0 x ( $in_size-$out_size); 
} 

if( ! seek ( OUT, -$end_bytes, 2 )) { # seek from end of file
	die("Cannot seek in file $out");
} 
if( ! print OUT $end_data ) {
	die("Cannot write data to file $out");	
}

close(OUT);
exit(0);



sub show_help {
		my $msg=shift;
        print STDERR ("##	$msg\n\n") if( $msg);
        print STDERR ("Version $version
This script copy 'begin_bytes' and 'end_bytes' from file 'in' to file 'out'
Usage: 
	$0 --in=IN --out=OUT [--begin_bytes=BB][--end_bytes=EB][--nobackup][ --help ]
Where:
	--in=IN - Original source file
	--out=OUT - Target file
	--begin_bytes=BB - how many bytes need be copy from begin of source file ( default 255 )
	--end_bytes=EB - how many bytes need be copy from the end of file (default 100k)
	--nobackup - Warning ! Do not make the backup copy of target file, directly fix all in target file  
	--help - this help
Sample:	${0} --in=1.mp4 --out=2.mp4 --nobackup
");
	if( $interactive ) {
		print "Press ENTER to exit:";
		<STDIN>;	
	}
	exit (100);
}

