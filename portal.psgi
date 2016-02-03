#!/usr/bin/perl
use strict;
use warnings;
use Plack::Builder;
use Plack::Request;
use lib '/usr/local/pf/lib';
use lib '/usr/local/pf/html/captive-portal/lib';

use captiveportal::DynamicRouting::Application;
use captiveportal::DynamicRouting::Factory;

use pf::Portal::ProfileFactory;
use pf::authentication;

my $app = sub {
    my $env = shift; # PSGI env
    my $session = $env->{'psgix.session'};
    my $req = Plack::Request->new($env);

    return $req->new_response(200)->finalize() if($req->path =~ /favicon/);

    my $mac = "00:11:22:33:44:55";
    my $profile = pf::Portal::ProfileFactory->instantiate($mac); 
    
    my $application = captiveportal::DynamicRouting::Application->new(session => $session, profile => $profile, request => $req, root_module_id => "root_module");
    $application->session->{client_mac} = $mac;

    my $factory = captiveportal::DynamicRouting::Factory->new();
    $factory->build_application($application);
    $application->execute();


    my $res = $req->new_response(200); # new Plack::Response
    $res->body($application->template_output);
    $res->finalize;
}; 

builder {
    enable 'Session';
    $app;
};
