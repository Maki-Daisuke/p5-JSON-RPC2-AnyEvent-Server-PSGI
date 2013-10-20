[![Build Status](https://travis-ci.org/Maki-Daisuke/p5-JSON-RPC2-AnyEvent-Server-PSGI.png?branch=master)](https://travis-ci.org/Maki-Daisuke/p5-JSON-RPC2-AnyEvent-Server-PSGI)
# NAME

JSON::RPC2::AnyEvent::Server::PSGI - PSGI adapter for JSON::RPC2::AnyEvent::Server

# SYNOPSIS

    use JSON::RPC2::AnyEvent::Server::PSGI;
    

    my $srv = JSON::RPC2::AnyEvent::Server->new(
        method => '[arg1, arg2]' => sub{
            my ($cv, $args) = @_;
            do_some_async_task(sub{ $cv->($result) });
        }
    );
    

    $srv->to_psgi_app;  # psgi app



# DESCRIPTION

JSON::RPC2::AnyEvent::Server::PSGI is a PSGI adapter for JSON::RPC2::AnyEvent::Server.
It converts JSON::RPC2::AnyEvent::Server object to a PSGI app.



# USAGE

Just call `to_psgi_app` method on JSON::RPC2::AnyEvent::Server object:

    my $srv = JSON::RPC2::AnyEvent::Server->new(...);
    my $psgi_app = $srv->to_psgi_app;

That's it!



# URL-QUERY MAPPING

While you can send requests as JSON of course, you can also send requests as
application/x-www-form-urlencoded format for your convinience. The mapping rule
between URL-query to JSON is similar to but slightly different from the rule of
<JSON-RPC 1.1 Draft|http://tonyg.github.io/erlang-rfc4627/doc/JSON-RPC-1-1-WD-20060807.html>.

For example:

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

Key-value pairs of URL-encoded query is translated into a JSON object (hash) and method to be
called is determined by the path-info (extra-path) part in the requested URI.

This module makes special treatment for requests with Content-Type header set to
"application/x-www-form-urlencoded".

You can even call RPC by HTTP GET request. The above request is also equivalent to
the following:

    GET /jsonrpc/do_it?foo=1&bar=2 HTTP/1.1
    Host: example.com
    



If a key is used multiple times, it is treated as a arrayref. For instance:

    GET /jsonrpc/do_it?foo=1&bar=2&foo=3 HTTP/1.1
    Host: example.com
    



is equivalent to:

    POST /jsonrpc HTTP/1.1
    Host: example.com
    Content-Type: application/json
    Content-Length: 81
    

    {"jsonrpc":"2.0", "id":null, "method":"do_it", "params":{"foo":[1, 3], "bar":2}}



# LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke (yet another) Maki <maki.daisuke@gmail.com>
