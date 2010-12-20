#!/perl
use strict;

use File::Temp qw/ tempdir /;
use Log::Log4perl qw(:easy);
use Test::Exception;
use Test::More 'no_plan';
use YAML;

use Wubot::SQLite;

Log::Log4perl->easy_init($ERROR);

my $tempdir = tempdir( "/tmp/tmpdir-XXXXXXXXXX", CLEANUP => 1 );

my $sqldb = "$tempdir/test.sql";

ok( my $sql = Wubot::SQLite->new( { file => $sqldb } ),
    "Creating new Wubot::SQLite object"
);

ok( $sql->dbh,
    "Forcing dbh connection to lazy load"
);

ok( -r $sqldb,
    "Checking that sql db was created: $sqldb"
);

{
    my $table = "test_table_1";
    my $schema = { column1 => 'INT',
                   column2 => 'VARCHAR(16)',
               };

    ok( $sql->create_table( $table, $schema ),
        "Creating a table $table"
    );

    is_deeply( [ $sql->get_tables() ],
               [ $table ],
               "Checking that table was created"
           );

    ok( $sql->insert( $table, { column1 => 123, column2 => "foo", column3 => "abc" }, $schema ),
        "Inserting hash into table"
    );

    is( ( $sql->query( "SELECT * FROM $table" ) )[0]->{column2},
        'foo',
        "Selecting row just inserted into table and checking column value"
    );

    is( ( $sql->query( "SELECT * FROM $table" ) )[0]->{column3},
        undef,
        "Checking that key not defined in schema was not inserted into table"
    );

    ok( $sql->delete( $table, { column1 => 123 } ),
        "Deleting entry just added"
    );

    is_deeply( [ $sql->query( "SELECT * FROM $table" ) ],
               [],
               "Checking that no rows left in the table"
           );

    $schema->{column3} = 'VARCHAR(32)';

    ok( $sql->insert( $table, { column1 => 234, column2 => "bar", column3 => "baz" }, $schema ),
        "Inserting hash with modified schema to include column3"
    );

    is( ( $sql->query( "SELECT * FROM $table" ) )[0]->{column3},
        'baz',
        "Selecting column3 just inserted into table and checking column value"
    );

}

{
    my $table = "test_table_2";
    my $schema = { column1 => 'INT',
                   column2 => 'VARCHAR(16)',
               };

    ok( $sql->insert( $table, { column1 => 123, column2 => "foo" }, $schema ),
        "Inserting hash into non-existent table"
    );

    is( ( $sql->query( "SELECT * FROM $table" ) )[0]->{column2},
        'foo',
        "Checking that table was created and data was inserted and retrieved"
    );

}

{
    my $table = "test_table_3";
    my $schema = { id      => 'INTEGER PRIMARY KEY AUTOINCREMENT',
                   column1 => 'INT',
               };

    is( $sql->insert( $table, { column1 => 123 }, $schema ),
        1,
        "Inserting hash into table, checking returned id"
    );

    is( $sql->insert( $table, { column1 => 234 }, $schema ),
        2,
        "Inserting hash into table, checking returned id"
    );

    is( $sql->insert( $table, { column1 => 345 }, $schema ),
        3,
        "Inserting hash into table, checking returned id"
    );

    is( ( $sql->query( "SELECT * FROM $table" ) )[0]->{id},
        1,
        "Checking auto-incrementing id"
    );

    is( ( $sql->query( "SELECT * FROM $table" ) )[1]->{id},
        2,
        "Checking auto-incrementing id"
    );
}


{
    my $table = "test_table_4";
    my $schema = { column1 => 'INT' };

    ok( $sql->insert( $table, { column1 => 0 }, $schema ),
        "Inserting hash into table with data value 0"
    );

    is( ( $sql->query( "SELECT * FROM $table" ) )[0]->{column1},
        0,
        "Checking that 0 was returned on query"
    );
}

{
    my $table = "test_table_5";
    my $schema = { column1 => 'INT', column2 => 'TEXT', column3 => 'INT', column4 => 'INT', column5 => 'INT' };

    my $data1 = { column1 => 1, column2 => 'foo foo foo', column3 => 3, column4 => 1, column5 => 0 };
    ok( $sql->insert( $table, $data1, $schema ),
        "Inserting test data 1 into table"
    );

    my $data2 = { column1 => 2, column2 => 'bar bar', column3 => 2, column4 => 1, column5  => 1 };
    ok( $sql->insert( $table, $data2, $schema ),
        "Inserting test data 2 into table"
    );

    my $data3 = { column1 => 3, column2 => 'baz', column3 => 1, column4 => 0, column5 => 1 };
    ok( $sql->insert( $table, $data3, $schema ),
        "Inserting test data into table"
    );

    {
        my @rows;
        ok( $sql->select( { tablename  => $table,
                            callback   => sub { push @rows, $_[0] },
                        } ),
            "Selecting all rows in table"
        );
        is_deeply( \@rows,
                   [ $data1, $data2, $data3 ],
                   "Selecting all rows"
               );
    }
    {
        my @rows;
        ok( $sql->select( { tablename => $table,
                            order     => 'column3',
                            callback  => sub { push @rows, $_[0] },
                        } ),
            "Selecting all rows in table ordered by column3"
        );
        is_deeply( \@rows,
                   [ $data3, $data2, $data1 ],
                   "Selecting all rows"
               );
    }
    {
        my @rows;
        ok( $sql->select( { tablename => $table,
                            order     => 'column3',
                            limit     => 1,
                            callback  => sub { push @rows, $_[0] },
                        } ),
            "Selecting all rows in table ordered by column3 with limit 1"
        );
        is_deeply( \@rows,
                   [ $data3 ],
                   "Selecting matching rows"
               );
    }
    {
        my @rows;
        ok( $sql->select( { tablename => $table,
                            order     => 'column3',
                            where     => { column4 => 1,
                                           column5 => 1,
                                       },
                            callback  => sub { push @rows, $_[0] },
                        } ),
            "Selecting all rows in table with conditions column4 = 1 and column5 = 1"
        );
        is_deeply( \@rows,
                   [ $data2 ],
                   "Selecting matching rows"
               );
    }
}


{
    my $table = "test_table_6";
    my $schema = { column1 => 'INT', column2 => 'INT', column3 => 'INT' };

    my $data1 = { column1 => 0, column2 => 1, column3 => 2 };
    ok( $sql->insert( $table, $data1, $schema ),
        "Inserting data1 hash into table"
    );

    my $data2 = { column1 => 4, column2 => 5, column3 => 6 };
    ok( $sql->insert( $table, $data2, $schema ),
        "Inserting data2 hash into table"
    );

    is_deeply( [ $sql->query( "SELECT * FROM $table" ) ],
               [ $data1, $data2 ],
               "Checking inserted data"
           );

    ok( $sql->update( $table, { column1 => 7 }, { column1 => 0 } ),
        "Calling update() to set column1 to 7 where column1 was 0"
    );

    $data1->{column1} = 7;

    is_deeply( [ $sql->query( "SELECT * FROM $table" ) ],
               [ $data1, $data2 ],
               "Checking row was updated"
           );
}


{
    my $table = "test_table_7";
    my $schema = { column1 => 'INT', column2 => 'INT', column3 => 'INT' };

    my $data1 = { column1 => 0, column2 => 1, column3 => 2 };
    ok( $sql->insert( $table, $data1, $schema ),
        "Inserting data1 hash into table"
    );

    my $data2 = { column1 => 4, column2 => 5, column3 => 6 };
    ok( $sql->insert( $table, $data2, $schema ),
        "Inserting data2 hash into table"
    );

    is_deeply( [ $sql->query( "SELECT * FROM $table" ) ],
               [ $data1, $data2 ],
               "Checking inserted data before calling update()"
           );

    $schema->{column4} = 'INT';

    ok( $sql->update( $table, { column4 => 7 }, { column1 => 0 }, $schema ),
        "Calling update() with updated schema containing column4"
    );

    $data1->{column4} = 7;
    $data2->{column4} = undef;

    is_deeply( [ $sql->query( "SELECT * FROM $table" ) ],
               [ $data1, $data2 ],
               "Checking row was updated with column4 data"
           );
}
{
    my $table = "test_table_8";
    my $schema = { column1 => 'INT', column2 => 'INT', column3 => 'INT' };

    my $data1 = { column1 => 0, column2 => 1, column3 => 2 };
    ok( $sql->insert_or_update( $table, $data1, { column1 => 3 }, $schema ),
        "Inserting data2 hash into table with insert_or_update and no pre-existing row"
    );

    my $data2 = { column1 => 4, column2 => 5, column3 => 6 };
    ok( $sql->insert_or_update( $table, $data2, { column1 => 7 }, $schema ),
        "Inserting data2 hash into table with insert_or_update and no pre-existing row"
    );

    is_deeply( [ $sql->query( "SELECT * FROM $table" ) ],
               [ $data1, $data2 ],
               "Checking inserted data before calling update()"
           );

    ok( $sql->insert_or_update( $table, { column1 => 7 }, { column1 => 0 }, $schema ),
        "Calling insert_or_update with row that already exists"
    );

    $data1->{column1} = 7;

    is_deeply( [ $sql->query( "SELECT * FROM $table" ) ],
               [ $data1, $data2 ],
               "Checking existing row was updated with insert_or_update"
           );
}


ok( $sql->disconnect(),
    "Closing SQLite file"
);

throws_ok( sub { $sql->query( "SELECT * FROM test_table_2" ) },
           qr/prepare failed.*inactive database handle/,
           "Checking that exception thrown when running a sql query on dead sql handle",
       );
