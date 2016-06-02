package Edge::Config;

use strict;
use vars qw($VERSION);
$VERSION = 0.12;

use Tie::Hash;
use base 'Tie::StdHash';
use Carp ();

sub safe_load {
    my $module = shift;
    $module =~ /^([A-Za-z0-9_\:]+)$/;
    $module = $1;
    eval qq{require $module};
}

# XXX 5.8.0 Tie::StdHash doesn't have new()
sub new {
    my $pkg = shift;
    $pkg->TIEHASH(@_);
}

sub TIEHASH {
    my($class, $configname) = @_;

    no strict 'refs';
    local $@;

    my $common_name = $ENV{EDGE_CONFIG_COMMON_NAME} || '_common';
    safe_load("${class}::${common_name}");
    die $@ if $@ && $@ !~ /Can\'t locate/;
    if ($configname) {
	safe_load("${class}::${configname}");
	die $@ if $@ && $@ !~ /Can\'t locate/;
    }
    my %config = %{join '::', $class, $common_name, 'Config'};
    %config = (%config, %{join '::', $class, $configname, 'Config'}) if $configname;

    # case sensitive hash
    %config = map { lc($_) => $config{$_} } keys %config
	unless $class->case_sensitive;
    bless \%config, $class;
}

sub FETCH {
    my($self, $key) = @_;
    unless (ref($self)) {
	require Carp;
	Carp::carp "Possibly misuse: $key called as a class method.";
    }
    $key = lc($key) unless $self->case_sensitive;
    Carp::croak "no such key: $key" 
	if (! exists $self->{$key} && $self->strict_param);
    $self->{$key};
}

sub STORE {
    my($self, $key, $value) = @_;
    $key = lc($key) unless $self->case_sensitive;
    Carp::croak "can't modify param $key"
	unless $self->can_modify_param;
    $self->{$key} = $value;
}

sub param {
    my $self = shift;
    if (@_ == 0) {
	return keys %{$self};
    }
    elsif (@_ == 1) {
	my $value = $self->FETCH(@_);
	if (wantarray && ref($value)) {
	    return @$value if ref($value) eq 'ARRAY';
	    return %$value if ref($value) eq 'HASH';
	}
	return $value;
    }
    else {
	$self->STORE(@_);
    }
}

# default value    
sub strict_param { 1; }
sub can_modify_param { 0; }
sub case_sensitive { 1; }

# nop for AUTOLOAD
sub DESTROY { }

use vars qw($AUTOLOAD);
sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://;

    # cache accessor
    $self->_create_accessor($AUTOLOAD);

    $self->param($AUTOLOAD, @_);
}

sub _create_accessor {
    my($self, $accessor) = @_;

    no strict 'refs';
    my $class = ref $self;
    *{"$class\::$accessor"} = sub {
	my $self = shift;
	$self->param($accessor, @_);
    };
}

1;
__END__

=head1 NAME

Edge::Config - Edge standard application configuration

=head1 SYNOPSIS

  package YourProject::Config;
  use base 'Edge::Config';
  
  package main;
  use YourProject::Config;

  # for OO-kids
  $config = YourProject::Config->new;
  $config = YourProject::Config->new($configname);
  
  # for hash lover
  tie %config, 'YourProject::Config';
  tie %config, 'YourProject::Config', $configname;


=head1 DESCRIPTION

see README.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@edge.co.jp>

=head1 SEE ALSO

perl(1).

=cut
