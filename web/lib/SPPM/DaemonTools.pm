package SPPM::DaemonTools;
$|++;
use v5.16;
use strict;
use warnings;
use utf8;

use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init(
    {
        level  => $DEBUG,
        layout => '[%P] %d %m%n',
        'utf8' => 1
    }
);

# importa o projeto ja
use FindBin::libs qw( base=web subdir=lib );

my $logger = get_logger();
our $BAIL_OUT = 0;

# importa as funcoes para o script.
no strict 'refs';
*{"main::$_"} = *$_ for grep { defined &{$_} } keys %SPPM::DaemonTools::;
use strict 'refs';

# coloca use strict/warnings sozinho
sub import {
    strict->import;
    warnings->import;
}

# logs
sub log_info {
    my (@texts) = @_;
    $logger->info( join ' ', @texts );
}

sub log_error {
    my (@texts) = @_;
    $logger->error( join ' ', @texts );
}

sub log_fatal {
    my (@texts) = @_;
    $logger->fatal( join ' ', @texts );
}

# daemon functions
sub log_and_exit {
    log_info "Graceful exit.";
    exit(0);
}

sub log_and_wait {
    log_info "SIG [TERM|INT] RECV. Waiting job...";
    $BAIL_OUT = 1;
}

# atalhos do daemon
sub ASKED_TO_EXIT {
    $BAIL_OUT;
}

sub EXIT_IF_ASKED {
    &log_and_exit() if $BAIL_OUT;
}

sub ON_TERM_EXIT {
    $SIG{TERM} = \&log_and_exit;
    $SIG{INT} = \&log_and_exit;
}

sub ON_TERM_WAIT {
    $SIG{TERM} = \&log_and_wait;
    $SIG{INT} = \&log_and_wait;
}

sub GET_SCHEMA {

    log_info "require SPPM::Schema...";
    require SPPM::Schema;

    # database
    my $db_host = $ENV{SPPM_DB_HOST} || 'localhost';
    my $db_pass = $ENV{SPPM_DB_PASS} || 'no-password';
    my $db_port = $ENV{SPPM_DB_PORT} || '5432';
    my $db_user = $ENV{SPPM_DB_USER} || 'postgres';
    my $db_name = $ENV{SPPM_DB_NAME} || 'sppm_dev';

    SPPM::Schema->connect(
        "dbi:Pg:host=$db_host;port=$db_port;dbname=$db_name",
        $db_user, $db_pass,
        {
            "AutoCommit"     => 1,
            "quote_char"     => "\"",
            "name_sep"       => ".",
            "pg_enable_utf8" => 1,
            "on_connect_do"  => "SET client_encoding=UTF8"
        }
    );

}


1;
