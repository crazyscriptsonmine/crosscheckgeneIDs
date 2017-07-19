#!/usr/bin/perl
use threads;
use Thread::Queue;
use IO::File;

open (IN, "<", $ARGV[0]);
my $usage = "Check GeneIDs (column 2) obtained from NCBI API with corresponding GeneNames [version 2: using Threads will result in multiple output files]\nTo use : perl $0 <tab-delimited file> <outputfilename> <organism>\n";
@ARGV == 3 or die $usage;

my $organism = $ARGV[2];

my $ii = 0;
my (%LIST, %NEWLIST);
while (<IN>){
	chomp;
	my @line = split("\t", $_,2);
	$LIST{$ii++} = [@line];
}
close (IN);
my @hashdetails = sort {$a <=> $b} keys %LIST;
push @VAR, [ splice @hashdetails, 0, 200 ] while @hashdetails;
$queue = new Thread::Queue();
my $builder=threads->create(\&main); #create thread for each subarray into a thread 
push @threads, threads->create(\&dbprocessor) for 1..10;
$builder->join; #join threads
foreach (@threads){$_->join;}


#SUBROUTINES
sub main {
  foreach my $count (0..$#VAR) {
                while(1) {
                        if ($queue->pending() < 100) {
                                $queue->enqueue($VAR[$count]);
                                last;
                        }
                }
        }
        foreach(1..10) { $queue-> enqueue(undef); }
}
sub dbprocessor { my $query; while ($query = $queue->dequeue()){ dbinput(@$query); } }

sub dbinput {
	my $rand = int(rand(1000));
	open (OUT2, ">", "$rand.txt");
	my $filename = @{ open_unique($ARGV[1]) }[1]; 
	foreach my $a (sort {$a <=> $b} @_) {
		if ($#{$LIST{$a}} > 0) {
			my @newlines = split("\t",(${$LIST{$a}}[1]));
			foreach my $ids (@newlines) {
				my $query = "perl /home/modupe/SCRIPTS/API/01-ncbi_search.pl -q '".$ids."[uid] and $organism' -d gene -r list -m 100 -o $rand";
				`$query`;
				my $filesee = `grep "This record " $rand`;
				unless (length($filesee) > 0) {
					my $checked = `head -n2 $rand | tail -n1`;
					my $realname = (split(" ", $checked))[1];
					if ((${$LIST{$a}}[0]) eq $realname) { print OUT2 ${$LIST{$a}}[0]."\t$ids\n";}
				}
			}
		} else {
			print OUT2 ${$LIST{$a}}[0]."\n";
		}
	}
	`cat $rand.txt > $filename`;
	`rm -rf $rand $rand.txt`;
}

sub open_unique {
    my $file = shift || '';
    unless ($file =~ /^(.*?)(\.[^\.]+)$/) {
        print "Bad file name: '$file'\n";
        return;
    }
    my $io;
    my $seq = '';
    my $base = $1;
    my $ext = $2;
    until (defined ($io = IO::File->new($base.$seq.$ext,O_WRONLY|O_CREAT|O_EXCL))) {
        last unless $!{EEXIST};
        $seq = '_0' if $seq eq '';
        $seq =~ s/(\d+)/$1 + 1/e;
    }
    return [$io,$base.$seq.$ext] if defined $io;
}
