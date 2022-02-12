#!/usr/bin/perl

use strict;
use warnings;

our $ACPI_BAT_DIR = "/proc/acpi/battery/BAT1";

our $KEY_PRESENT = "present";
our $KEY_CAP_STATE = "capacity state";
our $KEY_CAP_REMAINING = "remaining capacity";
our $KEY_CAP_DESIGN = "design capacity";
our $KEY_CAP_LAST_FULL = "last full capacity";
our $KEY_CAP_WARNING = "design capacity warning";
our $KEY_CAP_LOW = "design capacity low";

our $KEY_CHARGE_STATE = "charging state";
our $KEY_CHARGE_RATE = "present rate";

our $KEY_VOLT_DESIGN = "design voltage";
our $KEY_VOLT_PRESENT = "present voltage";


my @info_lines = `cat $ACPI_BAT_DIR/info`;
my @state_lines = `cat $ACPI_BAT_DIR/state`;

my %values = ();

foreach(@info_lines, @state_lines) {
    chomp;
    my ($key,$val) = split /:\s*/;
    $values{$key} = $val;
}


if($values{$KEY_PRESENT} ne "yes") {
    print "No Battery Present.\n";
    exit 1;
}

if($values{$KEY_CAP_STATE} ne "ok") {
    print "Capacity State not OK: [$values{$KEY_CAP_STATE}]\n";
    exit 2;
}

sub removeUnits {
    my ($v) = @_;
    my ($r, undef) = split / /, $v;
    return $r;
}


my $rate = removeUnits($values{$KEY_CHARGE_RATE});
$rate = -$rate if $values{$KEY_CHARGE_STATE} eq "discharging";

my $pct_full = removeUnits($values{$KEY_CAP_REMAINING})/removeUnits($values{$KEY_CAP_LAST_FULL});
my $time_left = 0;
my $overall = "UNKNOWN";
if($rate != 0) {
    if($values{$KEY_CHARGE_STATE} ne "discharging") {
	$time_left = (removeUnits($values{$KEY_CAP_LAST_FULL}) - removeUnits($values{$KEY_CAP_REMAINING}))/$rate;
	$overall = "CHARGING";
    } else {
	$time_left = (0 - removeUnits($values{$KEY_CAP_REMAINING}))/$rate;
	$overall = "DISCHARGING";
	$overall = "WARNING" if $values{$KEY_CHARGE_STATE} eq "discharging" && removeUnits($values{$KEY_CAP_REMAINING}) <= removeUnits($values{$KEY_CAP_WARNING});
	$overall = "LOW" if $values{$KEY_CHARGE_STATE} eq "discharging" && removeUnits($values{$KEY_CAP_REMAINING}) <= removeUnits($values{$KEY_CAP_LOW});
    }
} else {
    $overall = "FULL";
}

my $hours = int($time_left);
my $minutes = int(($time_left - $hours) * 60);
my $seconds = int((($time_left - $hours) * 60 - $minutes) * 60);



########################################3
#
#  OK, display the data!
#
printf("%-11s %3.0f%% %11s %2d:%02d (%6d mW) [%5d/%-5d mV] [%6d %6d %6d %6d %6d mWh]\n",
       $overall, $pct_full*100.0,
       $values{$KEY_CHARGE_STATE}, $hours, $minutes, $rate,
       removeUnits($values{$KEY_VOLT_PRESENT}),
       removeUnits($values{$KEY_VOLT_DESIGN}), removeUnits($values{$KEY_CAP_DESIGN}),
       removeUnits($values{$KEY_CAP_LAST_FULL}), removeUnits($values{$KEY_CAP_REMAINING}), removeUnits($values{$KEY_CAP_WARNING}), removeUnits($values{$KEY_CAP_LOW}
       ));

exit 0;


