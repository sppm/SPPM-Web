use strict;
use warnings;

use SPPM::Web;

my $app = SPPM::Web->apply_default_middlewares(SPPM::Web->psgi_app);
$app;

