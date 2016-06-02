use strict;
use Test;
BEGIN { plan tests => 15 }

package My::Config;
use base 'Edge::Config';

package My::Config::_common;
use vars qw(%Config);

$Config{HOGE} = 'hoge';

package My::Config::test;
use vars qw(%Config);

$Config{FOO} = 'bar';
$Config{REF} = [ 'goo', 'hoge' ];

package main;

# tie 
tie my %config, 'My::Config';
ok($config{HOGE}, 'hoge');
untie %config;

tie %config, 'My::Config', 'test';
ok($config{HOGE}, 'hoge');
ok($config{FOO}, 'bar');
untie %config;

# OO
my $config = My::Config->new;
ok($config->param('HOGE'), 'hoge');

$config = My::Config->new('test');
ok($config->param('HOGE'), 'hoge');
ok($config->param('FOO'), 'bar');

# accessor
ok($config->HOGE, 'hoge');
ok($config->FOO, 'bar');

# case insensitive
{
    local $^W;	# no warnings
    no strict 'refs';
    *{'My::Config::case_sensitive'} = sub { 0 };
    my $config_in = My::Config->new('test');
    ok($config_in->hoge, 'hoge');
    ok($config_in->foo, 'bar');
    *{'My::Config::case_sensitive'} = sub { 1 };
}

# modify test
sub My::Config::can_modify_param { 1 }
$config->param(FOO => 'goo');
ok($config->param('FOO'), 'goo');

# reference test
my @param = $config->param('REF');
ok("@param", 'goo hoge');

ok($config->param('REF')->[0], 'goo');

# ENV
$ENV{EDGE_CONFIG_COMMON_NAME} = 'test';
tie %config, 'My::Config';
ok($config{FOO}, 'bar');

# warning
my $warn;
$SIG{__WARN__} = sub { $warn .= shift };
eval { my $foo = My::Config->foo; };
ok($warn =~ /misuse/);






