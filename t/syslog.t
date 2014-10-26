#!/usr/bin/perl

# Test the syslog() method

my $syslog = 0;

BEGIN {
    require Exporter;
    eval { require Unix::Syslog; $u_syslog = 1 };
    eval { require Sys::Syslog; $s_syslog = 1 };

    if ($s_syslog)
    {
      Sys::Syslog->import qw(openlog closelog syslog setlogsock);
    }

};

use Test::More tests => 2;
use Safe::Logs qw(:Syslog);

SKIP:
{
    skip 'No Sys::Syslog found', 1 unless $s_syslog;
    eval {
	setlogsock('unix');
	openlog('Safe::Logs', LOG_PID | LOG_NDELAY, LOG_USER);
	syslog(LOG_NOTICE, "This is an escape --> \x1b from Sys::Syslog");
	closelog;
    };

    if ($@)
    {
	diag "The Sys::Syslog code failed with the following errors:\n$@\n";
	skip 'The syslog() code might need tweaking', 1;
    }

    ok(1, "sent through Sys::Syslog");
};

SKIP:
{
    skip 'No Unix::Syslog found', 1 unless $u_syslog;
    eval {
	openlog('Safe::Logs', 'pid,ndelay', 'user');
	syslog('notice', "This is an escape --> \x1b from Unix::Syslog");
	closelog;
    };

    if ($@)
    {
	diag "The Unix::Syslog code failed with the following errors:\n$@\n";
	skip 'The syslog() code might need tweaking', 1;
    }

    ok(1, "sent through Unix::Syslog");
};


    diag <<EOM

This test sends a message to the syslog() service using facility USER
and priority NOTICE. Please verify in your log file that these lines are 
present

                This is an escape --> [esc] from Sys::Syslog
                This is an escape --> [esc] from Unix::Syslog

Of course, if the test corresponding to one of the variants was skipped or
failed, you should not expect to see this line in your logs.

If you find this line in your logs, you can assume that this test passed.
If you cannot find a similar line in your logs, chances are that syslog()
needs a bit of tweaking in your system.
If you find the line above without the [esc] marker, this test was not
succesful in your platform.

EOM
    ;

