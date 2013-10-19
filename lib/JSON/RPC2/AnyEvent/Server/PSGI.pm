package JSON::RPC2::AnyEvent::Server::PSGI;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use AnyEvent;
use JSON;
use Plack::Request;
use Try::Tiny;

use JSON::RPC2::AnyEvent::Constants qw(ERR_PARSE_ERROR);
use JSON::RPC2::AnyEvent::Server;


sub JSON::RPC2::AnyEvent::Server::to_psgi_app {
    my ($self) = @_;
    sub{
        my $req = Plack::Request->new(shift);
        if ( $req->method eq 'GET' or  $req->method eq 'HEAD' ) {
            return _dispatch_url_query($self, $req);
        } elsif ( $req->method eq 'POST' ) {
            return $req->content_type =~ m|^application/x-www-form-urlencoded$|i
                ? _dispatch_url_query($self, $req)
                : _dispatch_json($self, $req);
        } else {
            return [405, ['Content-type' => 'text/plain'], ['Method Not Allowed']]
        }
    }
}

my $json = JSON->new->utf8;

sub _dispatch_url_query {
    my ($self, $req) = @_;
    sub{
        my $writer = shift->([200, ['Content-Type', 'application/json']]);
        my $params = $req->parameters;
        $self->dispatch({
            jsonrpc => '2.0',
            id      => undef,
            method  => substr($req->path_info, 1),
            params  => $params->mixed,
        })->cb(sub{
            my $res = shift->recv;
            $writer->write($json->encode($res));
            $writer->close;
        });
    };
}

sub _dispatch_body {
    my ($self, $req) = @_;
    sub{
        my $writer = shift->([200, ['Content-Type', 'application/json']]);
        try{
            my $hash = $json->decode($req->content);
            $hash->{id} = undef  unless exists $hash->{id};
            $self->dispatch($hash)->cb(sub{
                my $res = shift->recv;
                $writer->write($json->encode($res));
                $writer->close;
            });
        } catch {
            $writer->write($json->encode({
                jsonrpc => '2.0',
                id      => undef,
                error   => {code => ERR_PARSE_ERROR, message => 'Parse error', data => shift}
            }));
            $writer->close;
        }
    };
}


1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC2::AnyEvent::Server::PSGI - PSGI adapter for JSON::RPC2::AnyEvent::Server

=head1 SYNOPSIS

    use JSON::RPC2::AnyEvent::Server::PSGI;
    
    my $srv = JSON::RPC2::AnyEvent::Server->new(
        method => '[arg1, arg2]' => sub{
            my ($cv, $args) = @_;
            do_some_async_task(sub{ $cv->($result) });
        }
    );
    
    $srv->to_psgi_app;  # psgi app

=head1 DESCRIPTION

JSON::RPC2::AnyEvent::Server::PSGI is ...

=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

