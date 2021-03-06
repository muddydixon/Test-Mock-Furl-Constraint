use strict;
use warnings;
use Test::More;
use Test::Requires qw(Plack::Loader);

use Test::TCP;
use Test::Exception;
use Furl;
use Test::Mock::Furl::Constraint;

my $server = test_tcp(
    client => sub {
        my $port = shift;

        $Test::Mock::Furl::Constraint::DISABLE_EXTERNAL_ACCESS = 0;

        Test::Mock::Furl::Constraint->stub_request( any => "http://127.0.0.1:$port" )->add(sub {
            content => "mock";
        });

        my $furl = Furl->new;
        my $res = $furl->get("http://127.0.0.1:$port/foo/bar"); # no match, access extenral
        is $res->content, "ok";

        $res = $furl->get("http://127.0.0.1:$port"); # match, retrun mock response
        is $res->content, "mock";

        $Test::Mock::Furl::Constraint::DISABLE_EXTERNAL_ACCESS = 1;

        throws_ok {
            $furl->get("http://127.0.0.1:$port/foo/bar"); # no match, throw exception
        } qr/^disabled external access by Test::Mock::Furl::Constraint/;
    },
    server => sub {
        my $port = shift;
        my $app = sub {
            [200, [], ["ok"] ]
        };
        Plack::Loader->auto(
            host => "127.0.0.1",
            port => $port,
        )->run($app);
    }
);


done_testing;
