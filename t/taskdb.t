#!/perl
use strict;

use File::Temp qw/ tempdir /;
use Test::More 'no_plan';
use Test::Differences;
use YAML;

use Wubot::Logger;
use Wubot::Plugin::TaskDB;

my $tempdir = tempdir( "/tmp/tmpdir-XXXXXXXXXX", CLEANUP => 1 );


ok( my $check = Wubot::Plugin::TaskDB->new( { class      => 'Wubot::Plugin::OsxIdle',
                                            cache_file => '/dev/null',
                                            key        => 'OsxIdle-testcase',
                                        } ),
    "Creating a new TaskDB check instance"
);

my $config = { dbfile    => '/Users/wu/wubot/sqlite/tasks.sql',
               tablename => 'tasks',
           };

ok( my $results = $check->check( { config => $config } ),
    "Calling check() method"
);

print YAML::Dump $results;
