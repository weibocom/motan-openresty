# vim:set ft= ts=4 sw=4 et fdm=marker:
BEGIN {
    $ENV{LD_PRELOAD} = "mockeagain.so";
    $ENV{MOCKEAGAIN} = "w";
    $ENV{MOCKEAGAIN_WRITE_TIMEOUT_PATTERN} = 'hello, world';
    $ENV{TEST_NGINX_EVENT_TYPE} = 'poll';
}
# --with-poll_module
# events {
#     use poll;
# }
# https://github.com/iresty/programming-openresty-zh/blob/master/testing/testing-erroneous-cases.adoc

use Test::Nginx::Socket::Lua::Stream;
use FindBin qw($Bin);
my $root_path = $Bin;
our $MOTAN_P_ROOT=$root_path . "/../lib";
