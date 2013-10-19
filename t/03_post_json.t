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
    wanthash => '{x, y, z}' => sub{
        my ($cv, $args) = @_;
        $cv->send($args);
    },
)->to_psgi_app;


test_psgi $app, sub{
    my $cb = shift;

    my $json = JSON->new->utf8;

    my $res = $cb->(POST '/',
        'Content-Type' => 'application/json',
        Content => $json->encode({
            jsonrpc => '2,0',
            id      => 1,
            method  => 'echo',
            params => {hoge => 1, fuga => 2},
        })
    );
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, 1;
    ok(not exists $res->{error});
    is_deeply $res->{result}, {hoge => 1, fuga => 2};

    my $res = $cb->(POST '/unknown',  # extra-path is just ignored
        'Content-Type' => 'application/json',
        Content => $json->encode({
            jsonrpc => '2,0',
            id      => 2,
            method  => 'echo',
            params => [qw(one two three)],
        })
    );
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, 2;
    ok(not exists $res->{error});
    is_deeply $res->{result}, [qw(one two three)];

    my $res = $cb->(POST '/echo',  # extra-path is just ignored, and so, this is dispatched to 'wanthash'
        'Content-Type' => 'application/json',
        Content => $json->encode({
            jsonrpc => '2,0',
            id      => 3,
            method  => 'wanthash',
            params => [1, 2, 3],
        })
    );
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, 3;
    ok(not exists $res->{error});
    is_deeply $res->{result}, {x => 1, y => 2, z => 3};

    my $res = $cb->(POST '/echo',  # extra-path is just ignored, and so, this is invalid request
        'Content-Type' => 'application/json',
        Content => $json->encode({
            jsonrpc => '2,0',
            id      => 4,
            #method  => 'echo',  # intentionally
            params => [1, 2, 3],
        })
    );
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, 4;
    ok(not exists $res->{result});
    isa_ok $res->{error}, 'HASH';
    is $res->{error}{code}, -32600;

    my $res = $cb->(POST '/',
        'Content-Type' => 'text/plain',  # Content-body is parsed as JSON except application/x-www-form-urlencoded
        Content => $json->encode({
            jsonrpc => '2,0',
            id      => 5,
            method  => 'echo',  # intentionally
            params => ["OK"],
        })
    );
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, 5;
    ok(not exists $res->{error});
    is_deeply $res->{result}, ["OK"];
    
    done_testing;
};
