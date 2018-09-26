#!/usr/bin/perl
# korolev-ia@yandex.ru

use Getopt::Long;
use File::Copy;
use Video::Dumper::QuickTime;


my $version="2.0 2018.09.26";
my $interactive=0;

my $in='';
my $out='';
my $help=0;
my $nobackup=0;
my $debug=0;
if( $debug ) {
	use Data::Dumper;
}

GetOptions (
        'in=s' => \$in,
        'out=s' => \$out,
        'nobackup' => \$nobackup,
        'debug' => \$debug,
        "help|h|?"  => \$help ) or show_help();

show_help( "")  if( $help );
show_help( "Need both IN and Out files" ) if( !$in || !$out );
show_help( "Looks like files $in or $out do not exists" ) if( ! -f $in || ! -f $out );



################# PARSE ATOM RECORDS BEGIN #################

my $atomRecords=[];
my @foundAtomSections;
my $requiredAtomSections=[ 'ftyp', 'moov', 'mdat', 'uuid'  ];
my $atom = Video::Dumper::QuickTime->new( -filename => $in );
eval {$atom->Dump ()};
if( $@ ) {
	die( "Error during processing file $in: $@\n" );
}

my $dumpStr = $atom->Result ();
#print $dumpStr;

my @atomArr=split( /\n/, $dumpStr );



my $i=0;
foreach my $line( @atomArr ) {
	if( $line=~/^\./) {
		next;
	}
	if( $line=~/\'(\w+)\'(.+)\@\s+([\d+,]+)\s+\(.+\)\s+for\s+([\d+,]+)\s\(.+\):\s*/ ) {

		$atomRecords->[$i]->{'type'}=$1;
		$atomRecords->[$i]->{'description'}=$2;
		$atomRecords->[$i]->{'start'}=$3;
		$atomRecords->[$i]->{'lenght'}=$4;

		$atomRecords->[$i]->{'start'}=~s/,//g;
		$atomRecords->[$i]->{'lenght'}=~s/,//g;
		push( @foundAtomSections, $atomRecords->[$i]->{'type'} );
		if( $atomRecords->[$i]->{'type'} =~/mdat/ ) {
			$atomRecords->[$i]->{'lenght'}=8; # copy only first 8 bytes of mdat 
		}
		if( $debug ) {
			print "Parsed next atom records:";
			print Dumper( $atomRecords->[$i] );
		}
		$i++;
	}
}


#print Dumper( $requiredAtomSections, @foundAtomSections  );
if( ! check_array(  $requiredAtomSections, \@foundAtomSections  )) {
	die( "Cannot found required atom data in your IN video file");
}
################# PARSE ATOM RECORDS END #################


################# BEGIN READ DATA FROM SOURCE FILE #################
open( IN, $in ) || die( "Cannot open file $in: $!");
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev, $in_size, $atime,$mtime,$ctime,$blksize,$blocks) = stat(IN);
binmode( IN );


my $atomRecordsSize=scalar( @$atomRecords);
for( my $i=0; $i<$atomRecordsSize; $i++ ) {
	if( $debug ) {
		print "Read atom data for: ".$atomRecords->[$i]->{'type'}."\n";
	}	
	if( ! seek ( IN, $atomRecords->[$i]->{'start'}, 0 ) ) {
		die("Cannot seek in file $in : $!");
	} 
	my $data;
	if( ! read( IN, $data, $atomRecords->[$i]->{'lenght'} )) {
		die("Cannot read data from file $in : $!");
	}
	$atomRecords->[$i]->{'data'}=$data;
}
close(IN);
################# END READ DATA FROM SOURCE FILE #################




################# BEGIN BACKUP of target file #################
if( !$nobackup ) {
	my $backup_file="$out.".time();
	if( ! copy($out, $backup_file ) ) {
		die( "Backup copy file $out to $backup_file failed : $!");
	} 
}
################# END BACKUP of target file #################



################# BEGIN SAVE DATA TO TARGET FILE #################
open( OUT, '+<', $out )|| die( "Cannot open file $out: $!");
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,	$out_size ,$atime,$mtime,$ctime,$blksize,$blocks) = stat(OUT);
binmode( OUT );

# fix if lenght of target file is shortest than lenght of source file
if( $in_size!=$out_size ) {
	print STDERR "Size of file IN is $in_size, but file size of file OUT is $out_size. Cannot correctly fix bytes in the end of file OUT\n";
	# increase file to required size
	if( ! seek ( OUT, 0, 2 )) {
		die("Cannot seek in file $out : $!");
	} 
	print OUT 0 x ( $in_size-$out_size); 
} 


for( my $i=0; $i<$atomRecordsSize; $i++ ) {
		if( $debug ) {
			print "Written atom data for: ".$atomRecords->[$i]->{'type'}."\n";
		}			
		if( ! seek ( OUT, $atomRecords->[$i]->{'start'}, 0 ) ) {
			die("Cannot seek in file $out : $!");
		}
		if( ! print OUT $atomRecords->[$i]->{'data'} ) {
			die("Cannot write data to file $out : $!");
		} 
}

close(OUT);
print "All ok. Movie atom was copied from '$in' to '$out'\n";
exit(0);



sub show_help {
		my $msg=shift;
        print STDERR ("##	$msg\n\n") if( $msg);
        print STDERR ("Version $version
This script copy movie atoms ( moov, mdat, ftyp, etc) from video file 'in' to file 'out'
This can be usefull if your video file have broken header ( eg continius copy from video camera ).
Usage: 
	$0 --in=IN --out=OUT [--nobackup][ --help ]
Where:
	--in=IN - Original source file
	--out=OUT - Target file
	--nobackup - Warning ! Do not make the backup copy of target file, directly fix all in target file  
	--debug - show debug information
	--help - this help
Sample:	${0} --in=1.mp4 --out=2.mp4 --nobackup
");
	if( $interactive ) {
		print "Press ENTER to exit:";
		<STDIN>;	
	}
	exit (100);
}

sub check_array {
    my ( $test, $source ) = @_;
    my %exists = map { $_ => 1 } @$source;
    foreach my $ts ( @{$test} ) {
        return if ! $exists{$ts};
    }
    return 1;
}