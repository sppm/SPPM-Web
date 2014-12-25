# Criado em 2014-12-22
# Script para importação dos artigos do site sao-paulo.pm.org
# este script le os jsons gerados pelo scan_article_to_json.pl e cria
# as devidas versoes no banco de dados.


use FindBin qw($Bin);
use lib "$Bin/../lib";

use SPPM::DaemonTools;
use utf8;

use warnings;
use File::Find;

use Cpanel::JSON::XS;

use File::Slurp::Tiny 'read_file';
use Digest::MD5 qw/md5_hex/;
use open qw/:std :utf8/;

# root paths

my $json_src = "$Bin/../../cache/jsons";
log_fatal "$json_src not found" unless -d $json_src;


my $unknown = '0' x 32;

my $schema = GET_SCHEMA;

my $article_rs = $schema->resultset('Article');


log_info 'looping', $json_src, 'dir...';

find(
    sub {
        return if -d $File::Find::name || $_ =~ /\.md5$/;

        my $dir  = "$File::Find::dir";
        my $qdir = quotemeta($json_src);
        $dir =~ s/$qdir//;

        my $fname    = $_;
        my $relpath  = "$dir/$fname";
        my $fullpath = "$json_src/$relpath";

        my $article = decode_json(read_file( $fullpath, binmode => ':raw' ) );

        my $content      = delete $article->{content};
        my $html_content = delete $article->{html_content};

        $article_rs->upsert($article);

    },
    $json_src
);
log_info 'done.';

