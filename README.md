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

JSON::RPC2::AnyEvent::Server::PSGI is ...

# LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke (yet another) Maki <maki.daisuke@gmail.com>
