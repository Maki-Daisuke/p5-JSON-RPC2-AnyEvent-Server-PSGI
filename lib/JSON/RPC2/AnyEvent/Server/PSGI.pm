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

sub _dispatch_json {
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

JSON::RPC2::AnyEvent::Server::PSGI is a PSGI adapter for JSON::RPC2::AnyEvent::Server.
It converts JSON::RPC2::AnyEvent::Server object to a PSGI app.


=head1 USAGE

Just call C<to_psgi_app> method on JSON::RPC2::AnyEvent::Server object:

    my $srv = JSON::RPC2::AnyEvent::Server->new(...);
    my $psgi_app = $srv->to_psgi_app;

That's it!


=head1 URL-QUERY MAPPING

While you can send requests as JSON of course, you can also send requests as
application/x-www-form-urlencoded format for convinience. For example:

    POST /jsonrpc/do_it HTTP/1.1
    Host: example.com
    Content-Type: application/x-www-form-urlencoded
    Content-Length: 11
    
    foo=1&bar=2

This request is equivalent to the below: 

    POST /jsonrpc HTTP/1.1
    Host: example.com
    Content-Type: application/json
    Content-Length: 75
    
    {"jsonrpc":"2.0", "id":null, "method":"do_it", "params":{"foo":1, "bar":2}}

Key-value pairs of URL-encoded query is translated into a JSON object and method to be
called is determined by the path-info (extra-path) part in the requested URI.

This module makes special treatment for requests with Content-Type header set to
"application/x-www-form-urlencoded".

You can even call RPC by HTTP GET request. The above request is also equivalent to
the following:

    GET /jsonrpc?foo=1&bar=2 HTTP/1.1
    Host: example.com
    


=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

