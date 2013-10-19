requires 'perl', '5.008001';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Exception';
    requires 'Plack::Test';
    requires 'HTTP::Request::Common';
};

requires 'JSON::RPC2::AnyEvent::Server';
requires 'Plack';
requires 'Try::Tiny';
