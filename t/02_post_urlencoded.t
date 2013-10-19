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
    wantarray => '[foo, bar, baz]' => sub{
        my ($cv, $args) = @_;
        $cv->send($args);
    },
)->to_psgi_app;


test_psgi $app, sub{
    my $cb = shift;

    my $res = $cb->(POST '/echo', Content => {hoge => 1, fuga => 2});
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, undef;
    ok(not exists $res->{error});
    is_deeply $res->{result}, {hoge => 1, fuga => 2};

    $res = $cb->(POST '/echo/method', Content => {hoge => 1, fuga => 2});
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, undef;
    ok(not exists $res->{result});
    isa_ok $res->{error}, 'HASH';
    is $res->{error}{code}, -32601;

    $res = $cb->(POST '/', Content => {hoge => 1, fuga => 2});
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, undef;
    ok(not exists $res->{result});
    isa_ok $res->{error}, 'HASH';
    is $res->{error}{code}, -32601;

    $res = $cb->(POST '/echo', Content => [hoge => 1, fuga => 2, hoge => 3, hoge => 4]);
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, undef;
    ok(not exists $res->{error});
    is_deeply $res->{result}, {hoge => [1, 3, 4], fuga => 2};

    $res =  $cb->(POST '/wantarray', Content => {foo => 'one', baz => 'three', bar => 'two'});
    is $res->code, 200;
    is $res->header('Content-type'), 'application/json';
    lives_ok{ $res = JSON->new->decode($res->content) };
    is $res->{id}, undef;
    ok(not exists $res->{error});
    is_deeply $res->{result}, [qw(one two three)];

    done_testing;
};
