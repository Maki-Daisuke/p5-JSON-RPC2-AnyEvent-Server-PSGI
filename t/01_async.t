use strict;
use Test::More;
use Test::Exception;

BEGIN{
    $ENV{PLACK_TEST_IMPL} = 'Server';  # Cannot test non-blocking app with MochHTTP
}
use Plack::Test;
use HTTP::Request::Common;

use AnyEvent;
use JSON;
use JSON::RPC2::AnyEvent::Server::PSGI;

my $app = JSON::RPC2::AnyEvent::Server->new(
    echo => sub {
        my ($cv, $args) = @_;
        my $w; $w = AE::timer 0.5, 0, sub{ undef $w; $cv->send($args); };
    },
)->to_psgi_app;

test_psgi $app, sub{
    my $cb = shift;
    my $res = $cb->(GET '/echo?hoge=1&fuga=2');
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is_deeply $res->{result}, {hoge => 1, fuga => 2};
    done_testing;
};
