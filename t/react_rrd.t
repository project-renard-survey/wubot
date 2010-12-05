#!/perl
use strict;
use warnings;

use File::Temp qw/ tempdir /;
use Test::More 'no_plan';

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);
my $logger = get_logger( 'default' );

use Wubot::Reactor::RRD;

ok( my $rrd = Wubot::Reactor::RRD->new(),
    "Creating a new 'rrd' reactor object"
);

{
    my $tempdir = tempdir( "/tmp/tmpdir-XXXXXXXXXX", CLEANUP => 1 );
    my $key     = "testcase-key";
    my $field   = "somename";

    my $config = { base_dir  => $tempdir,
                   fields    => { somename => 'GAUGE' },
                   filename  => 'data',
               };

    ok( $rrd->react( { $field => 100, key => $key }, $config ),
        "Calling 'react' with test message"
    );

    ok( -d "$config->{base_dir}/rrd",
        "Checking that rrd subdirectory was created"
    );

    ok( -d "$config->{base_dir}/rrd/$key",
        "Checking that $key subdirectory was created"
    );

    ok( -r "$config->{base_dir}/rrd/$key/data.rrd",
        "Checking that rrd file was created using key field"
    );

    ok( -d "$config->{base_dir}/graphs",
        "Checking that graph directory was created"
    );

    ok( -d "$config->{base_dir}/graphs/$key",
        "Checking that graph subdirectory $key was created"
    );

    ok( -r "$config->{base_dir}/graphs/$key/data-daily.png",
        "Checking that png was created use key field as basename"
    );

    sleep 1;

    ok( $rrd->react( { $field => 200.5, key => $key }, $config ),
        "Calling 'react' with test message"
    );

}

{
    my $tempdir = tempdir( "/tmp/tmpdir-XXXXXXXXXX", CLEANUP => 1 );
    my $key     = "testcase-key";
    my @fields  = qw( somename1 somename2 );

    my $config = { base_dir  => $tempdir,
                   fields    => { somename1 => 'GAUGE',
                                  somename2 => 'GAUGE',
                              },
                   filename  => 'data2',
               };

    ok( $rrd->react( { 'somename1' => 100, 'somename2' => 200, key => $key }, $config ),
        "Calling 'react' with test message"
    );

    ok( -d "$config->{base_dir}/rrd",
        "Checking that rrd subdirectory was created"
    );

    ok( -d "$config->{base_dir}/rrd/$key",
        "Checking that $key subdirectory was created"
    );

    ok( -d "$config->{base_dir}/graphs",
        "Checking that graph directory was created"
    );

    ok( -d "$config->{base_dir}/graphs/$key",
        "Checking that graph subdirectory $key was created"
    );

    ok( -r "$config->{base_dir}/rrd/$key/data2.rrd",
        "Checking that rrd file was created using key field"
    );

    ok( -r "$config->{base_dir}/graphs/$key/data2-daily.png",
        "Checking that png was created use key field as basename"
    );

}
