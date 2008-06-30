package t::Tools;

# inspired by Test::Fixture::DBIC::Schema

use strict;
use warnings;

use Artemis::Schema::ReportsDB;
use Artemis::Reports::Web;
use Artemis::Config;

my $reportsdb_schema;

sub setup_reportsdb {

        # explicitely prefix into {test} subhash of the config file,
        # to avoid painful mistakes with deploy

        my $dsn = Artemis::Config->subconfig->{test}{database}{ReportsDB}{dsn};

        my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
        unlink $tmpfname;

        $reportsdb_schema = Artemis::Schema::ReportsDB->connect($dsn,
                                                                Artemis::Reports::Web->config->{test}{database}{ReportsDB}{username},
                                                                Artemis::Reports::Web->config->{test}{database}{ReportsDB}{password},
                                                                { ignore_version => 1 }
                                                               );
        $reportsdb_schema->deploy;
        $reportsdb_schema->upgrade;
}

sub import {
        my $pkg = caller(0);
        no strict 'refs';       ## no critic.
        *{"$pkg\::reportsdb_schema"} = sub () { $reportsdb_schema };
}

setup_reportsdb;

1;
