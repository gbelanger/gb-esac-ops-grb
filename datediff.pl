#!/usr/bin/perl

my $nArgs = $#ARGV +1;

if ( $nArgs != 6 && $nArgs != 12 ) {
  print "Usage: datediff.pl y1 m1 d1 y2 m2 d2  OR  datediff.pl y1 m1 d1 h1 m1 s1 y2 m2 d2 h2 m2 s2\n";
  exit 0;
  }

if ( $nArgs == 6 ) {

  # Use this for dates with Y M D

  my $y_1 = $ARGV[0];
  my $mo_1 = $ARGV[1];
  my $d_1 = $ARGV[2];

  my $y_2 = $ARGV[3];
  my $mo_2 = $ARGV[4];
  my $d_2 = $ARGV[5];

  use Date::Calc qw(Delta_Days);
  @earlierDate = ($y_1, $mo_1, $d_1);
  @laterDate = ($y_2, $mo_2, $d_2);
  $diff = Delta_Days(@earlierDate, @laterDate);
  print "$diff\n"

}

else {

  # Use this for dates with Y M D H M S

  my $y1 = $ARGV[0];
  my $mo1 = $ARGV[1];
  my $d1 = $ARGV[2];

  my $h1 = $ARGV[3];
  my $m1 = $ARGV[4];
  my $s1 = $ARGV[5];

  my $y2 = $ARGV[6];
  my $mo2 = $ARGV[7];
  my $d2 = $ARGV[8];

  my $h2 = $ARGV[9];
  my $m2 = $ARGV[10];
  my $s2 = $ARGV[11];

  use Date::Calc qw(Delta_DHMS);
  @earlierDate = ($y1, $mo1, $d1, $h1, $m1, $s1);
  @laterDate = ($y2, $mo2, $d2, $h2, $m2, $s2);
  @diff = Delta_DHMS(@earlierDate, @laterDate);

  $days = $diff[0] + $diff[1]/24 + $diff[2]/(24*60) + $diff[3]/86400;
  print "$days\n"
}

