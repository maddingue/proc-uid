#!/usr/bin/perl -wT
use strict;
use Test;

# These tests are to ensure that Proc::UID's functions operate
# correctly when running as true root (as opposed to suid root).

BEGIN {
	if ($< == 0 and $> == 0) {
		plan tests => 28;
	} else {
		print "1..0 # Skipped, this file must be run as root.\n";
		exit 0;
	}
}

my $TEST_UID = 1000;	# Any non-root UID.
my $TEST_GID = 1000;

use Proc::UID qw(geteuid getruid getsuid
		 seteuid setruid setsuid
		 setsgid getsgid
		 setuid_permanent);

ok(1);	# Loaded Proc::UID.

# 3 tests
# First, make sure we really look like root.
ok(geteuid(),0,"Effective UID not 0");
ok(getruid(),0,"Real UID not 0");
ok(getsuid(),0,"Saved UID not 0");

# 12 tests
# Now, let's try changing our UIDs around.
# We take each UID, change it, then change it back again.

ok(eval {seteuid($TEST_UID); "ok"},"ok","Could not set effective UID");
ok($>,$TEST_UID,"Effective UID not changed.");
ok(eval {seteuid(0); "ok"},"ok","Could not reset effective UID");
ok($>,0,"Effective UID not reset.");

ok(eval {setruid($TEST_UID); "ok"},"ok","Could not set real UID");
ok($<,$TEST_UID,"Real UID not changed.");
ok(eval {setruid(0); "ok"},"ok","Could not reset effective UID");
ok($<,0,"Real UID not reset.");

ok(eval {setsuid($TEST_UID); "ok"},"ok","Could not set saved UID");
ok(getsuid(),$TEST_UID,"Saved UID not changed.");
ok(eval {setsuid(0); "ok"},"ok","Could not reset effective UID");
ok(getsuid(),0,"Saved UID not reset.");

# 2 tests
# A few tests for our saved gids.

ok(eval {setsgid($TEST_GID); "ok"},"ok","Could not set saved GID");
ok(getsgid(),$TEST_GID,"Saved GID not saved");

# 10 tests
# Finally, drop our privileges permanently, and ensure we can't get
# them back using a variety of methods.

ok(eval {setuid_permanent($TEST_UID); "ok" },"ok",
	"Could not drop permanently drop UID.");

# Make sure they appear dropped.
ok($<,$TEST_UID,"Real UID not dropped according to \$<");
ok($>,$TEST_UID,"Effective UID not dropped according to \$>");
ok(geteuid(),$TEST_UID,"Effective UID not dropped according to geteuid()");
ok(getruid(),$TEST_UID,"Effective UID not dropped according to getruid()");
ok(getsuid(),$TEST_UID,"Saved UID not dropped");

$< = 0; ok($<,$TEST_UID,"Managed to restore real UID using \$<");
$> = 0; ok($>,$TEST_UID,"Managed to restore effective UID using \$>");

eval { setsuid(0); }; ok($@,qr/Could not/,"Invalid setsuid appeared to work");
ok(getsuid(),$TEST_UID,"Managed to restore saved UID");
