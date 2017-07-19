#!/usr/bin/perl
use strict;
my $usage = "Check GeneIDs (column 2) obtained from NCBI API with corresponding GeneNames\nTo use : perl $0 <tab-delimited file> <outputfilename> <organism>\n";
@ARGV == 3 or die $usage;

open (IN, "<", $ARGV[0]);
open(OUT, ">", $ARGV[1]);
my 
$organism = $ARGV[2];
my $rand = int(rand(1000));
while (<IN>){
	chomp;
	my @line = split("\t", $_,2);
	if ($#line > 0){
		my @newlines = split("\t",$line[1]);
		foreach my $ids (@newlines) {
			my $query = "perl /home/modupe/SCRIPTS/API/01-ncbi_search.pl -q '".$ids."[uid] and $organism' -d gene -r list -m 100 -o $rand";
			#print $query; 
			`$query`;
			my $filesee = `grep "This record was replaced with GeneID" $rand`;
                        unless (length($filesee) > 0) {
				my $checked = `head -n2 $rand | tail -n1`;
				my $realname = (split(" ", $checked))[1];
				#print $realname," ", $line[0],"\n";
				if ($line[0] eq $realname) { print OUT "$line[0]\t$ids\n";} 
				#else { print " no\n";}
			}
		}
	} else { print OUT "$line[0]\n"; }
}
close (IN);
`rm -rf $rand`;
