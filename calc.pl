#!/usr/bin/perl
#
# v 22.01.2002
# Alexey Vikhlinin
# http://hea-www.harvard.edu/~alexey/calc.html
# some code is taken from Math::Trig;
#
# This script is provided 'as is' and without any warranty. For example,
# I'm not paying if you wrap it in a web form and your files get erased:)
#

$log10 = 2.30258509299405;
$pi = 3.14159265358979;
#-----------------------------------------------------------------------------
use constant pi    => 3.14159265358979;
use constant EE    => 2.718281828459045; # exp(1). Not 'e' because e is charge of electron

use constant Msun  => 1.9891e+33;
use constant Lsun  => 3.826e+33;
use constant Rsun  => 6.9599e+10;
use constant c     => 2.9979245620e+10;      # speed of light
use constant G     => 6.67259e-08;           # gravitational constant
use constant e     => 4.8032068e-10;         # charge of electron
use constant h     => 6.6260755e-27;         # erg*s Planck's constant
use constant me    => 9.1093897e-28;         # mass of electron
use constant mp    => 1.6726231e-24;         # mass of proton
use constant alpha => 1/(h*c/(2*pi*e**2));   # fine structure constant
use constant sigmaT=> 6.6524616e-25;         # Thomson cross section=8pi/3*re^2
use constant k     => 1.380658e-16;          # (erg/K)  Boltzman constant
use constant NA    => 6.0221367e+23;         # mol^-1 Avogadro constant
use constant sigma => 5.67051e-5;            # Stefan-Boltzmann constant

use constant keV => 1.602192e-9;  use constant eV  => 1.602192e-12;   # erg
use constant pc  => 3.085678e+18; use constant kpc => 1000*pc; use constant Mpc => 1000*kpc;
#-----------------------------------------------------------------------------
use constant sec  => 1; use constant s => sec;   
# `sec' is used internally
use constant hour => 3600; use constant hr => hour;        # not 'h' because h is Planck's const
use constant day  => 24*hour; use constant yr => 365.242*day; use constant year=>yr;
use constant lb   => 453.5924;
use constant oz   => lb/16;
use constant A    => 1e-8;
use constant cm   => 1; use constant meter=>100; use constant m=>meter; use constant km=>1e5;
# `meter' is used internally
use constant inch => 2.54; use constant ft => 12*inch; use constant feet => ft;
use constant mile => 1.609344e+05; use constant mph   => mile/hour;
use constant knot => 5.144444e+01; use constant knots => knot;
use constant kg   => 1e3;
use constant W    => 1e7;                # Watt
use constant Jy => 1e-26*W/meter**2; use constant mJy => 1e-3*Jy;   # per Hz
use constant deg  => pi/180; use constant arcmin => deg/60; use constant arcsec => arcmin/60;

sub ln {log($_[0]);}
sub lg {log($_[0])/$log10;}
sub fact {$s=1; for ($i=2;$i<=$_[0];$i++) {$s*=$i;} return $s;}
sub r2d {$_[0]*180.0/$pi}
sub atan {atan2($_[0],1)}
sub tan {my $z = $_[0]; sin($z)/cos($z)}
sub acos {my $z = $_[0]; atan2(sqrt(1-$z*$z), $z)}
sub asin {my $z = $_[0]; atan2($z, sqrt(1-$z*$z))}
sub C {fact($_[0])/(fact($_[1])*fact(($_[0]-$_[1])))}
sub sind {sin($_[0]*pi/180)}
sub cosd {cos($_[0]*pi/180)}
sub tand {tan($_[0]*pi/180)}
sub asind {asin($_[0])*180/pi}
sub acosd {acos($_[0])*180/pi}
sub atand {atan($_[0])*180/pi}
sub asinh {my $x=$_[0]; log($x+sqrt(1+$x**2))}
sub acosh {my $x=$_[0]; log($x+sqrt($x**2-1))}
sub atanh {my $x=$_[0]; 0.5*(log(($x+1)/(1-$x)))}
sub acoth {my $x=$_[0]; atanh($x)}
sub nint {
  my $x = $_[0]; 
  my $n = int($x);
  if ( $x > 0 ) {
    if ( $x-$n > 0.5) {
      return $n+1;
    }
    else {
      return $n;
    }
  }
  else {
    if ( $n-$x > 0.5) {
      return $n-1;
    }
    else {
      return $n;
    }
  }
}
sub CtoF { my $x = $_[0]; return 9*$x/5+32; }
sub FtoC { my $x = $_[0]; return ($x-32.)*5./9.;}
sub lgamma {  # per code from numerical recipies
  my $xx = $_[0];
  my $j, $ser, $stp, $tmp, $x, $y;
  my @cof = (0.0, 76.18009172947146, -86.50532032941677,
	     24.01409824083091, -1.231739572450155, 0.1208650973866179e-2,
	     -0.5395239384953e-5);
  my $stp = 2.5066282746310005;
    
  $x = $xx; $y = $x;
  $tmp = $x + 5.5;
  $tmp = ($x+0.5)*log($tmp)-$tmp;
  $ser = 1.000000000190015;
  foreach $j ( 1 .. 6 ) {
    $y+=1.0;
    $ser+=$cof[$j]/$y;
  }
  return $tmp + log($stp*$ser/$x);
}

sub gamma { 
  return exp(&lgamma ($_[0]));
}


if ($ENV{"CALCRC"}) {do $ENV{"CALCRC"};} # personal settings

sub doeval {
  $origexpr = $_;
  s/(^|[^\w\+-])([\+-]?(?:\d+\.?\d*|\.\d+))([eE])([\+-]?\d+(?=$|[^\d\.]))/$1$2\371$4/g; # 1.5e5 -> 1.5ù5 so that scientific notations don't mess up with the
         # charge of electron
  s/(^\'|\'$)//g; # Trim single quotes in the beg/end of string

  s/(^|[^a-zA-Z])s($|[^a-zA-Z])/$1sec$2/g;  # s -> sec
  s/(^|[^a-zA-Z])m($|[^a-zA-Z])/$1meter$2/g;# m -> meter
  s/(\W)([a-zA-Z]\w*)!/$1fact($2)/g;  # $na_3! -> fact($n)
  s/(\d)\s*\(/$1*\(/g;            # 10(me+mp) -> 10*(me+mp)
  s/atan2\*\(/atan2\(/g;          # but `atan2(' -> `atan2('
#  s/(^|[^\w\371\+-])([\+-]?(?:\d+\.?\d*|\.\d+)(?:\371[\+-]?\d+)?)([a-zA-Z]+)(?=$|\W)/$1\($2*$3\)/g;              # 45mp -> (45*mp) (to be able to 6me/3mp)
  s/(^|[^\w\371])((?:\d+\.?\d*|\.\d+)(?:\371[\+-]?\d+)?)([a-zA-Z]+)(?=$|\W)/$1\($2*$3\)/g;              # 45mp -> (45*mp) (to be able to 6me/3mp)
  s/([\d\.\)])\s*([a-zA-Z])/$1*$2/g; # 45a -> 45*a; )a-> )*a
  s/(\w)\s+([a-zA-Z\d])/$1*$2/g;  # Msun c**2 -> Msun*c**2
  s/(^|\W)([abdfgijln-rt-z])(?=$|\W)/$1\$$2/g; # single letter lower-case 
                                               # variables 
  s{/([abdfgijln-r-t-z])(?=$|\W)}{/\$$1}g;     # preceeded and followed by a 
                                       # non-word character are replaced
                                       # with $variable; second substitution
                                       # is needed in cases /n, because $1
                                       # works incorrectly
  s/(\d+)!/fact($1)/g; # 10! -> fact(10)
  # factorial after the numbers is done last because otherwise the typo
  # "calc 3.5!" results (silently) in 3.*fact(5)
  s/(^|[^\w\.])0+(\d)/$1$2/g; # trim leading zeros in numbers

  s/\371/e/g; # 1.5ù5 -> 1.5e5 THIS MUST BE THE LAST TRANSFORMATION

  if ($ENV{"CALCDEBUG"}) {print STDERR "Debug: ",$_," format: ",$format,"\n";}
  if ( !defined($_result_ = eval "$_") ) {
    print STDERR "wrong expr: $origexpr -> $_\n";
  }
     
  if ( $commandline || (! /=/) ) { # ignore assignments in the stdin mode
    if ($format =~ /^%l/ ) {
      print $_result_,"\n";
    }
    else {
      printf "$format\n", $_result_;
    }
  }
}


# ENV VARIABLES
if ($ENV{"CALCFORMAT"}) {$format = $ENV{"CALCFORMAT"};} else {$format = "%g"}
if ($ENV{"CALCDEBUG"})  {$debug=1} else {$debug=0}

$_ = "@ARGV";

if ( /^-h$|^-help$/ ) {
  &printconst;
  exit 0;
}


if ( /\w/ ) {
  $commandline = 1;
  &doeval;                                 
}
else {
  while ( <STDIN> ) {
    chop;
    $commandline = 0;
    &doeval;
  }
}

sub printconst {
  $scriptname = $0;
  while ( <DATA> ) { print; }
  open (SCR,$scriptname) || die "Can't open $scriptname";
  while ( <SCR> ) {
    if (/^use constant |^\#------/) {
      s/use constant //g;
      s/=>/=/g;
      print;
    }
  }
}

__END__
Available functions:
-------------------
exp, log, abs, sqrt, sin, cos, tan, asin, acos, atan, atan2(x,y)=atan(x/y)
sind, cosd, tand, asind, acosd, atand --- degree based trig. functions; 
                                      you can use the 'deg' constant instead.
ln(x),lg(x) -> log_e(x), log_10(x)
gamma(x), lgamma(x) - Gamma and log(Gamma) functions
r2d(x)  = x*180/pi;  you can use the 'deg' constant instead
fact(n) = n!, C(n,k) = n!/(k!(n-k)!)
int, nint - integer portion and nearest integer
CtoF,FtoC - convert between degrees centrigrade and Fahrenheit.

Examples of usage can be found on http://hea-www.harvard.edu/~alexey/calc.html

Available constants (all units are in the cgs system):

