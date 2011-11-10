package FvwmLayout::Page;
use strict;
use warnings;

=head1 NAME

FvwmLayout::Page - FvwmLayout class for keeping track of page info.

=head1 SYNOPSIS

    use base qw(FvwmLayout::Page);

=head1 DESCRIPTION

This module keeps track of information for one Fvwm page.

=cut

use lib `fvwm-perllib dir`;

use base qw( Class::Base );

our $ERROR = '';
our $DEBUG = 0 unless defined $DEBUG;

=head2 init

Initialize.

=cut
sub init {
    my ($self, $config) = @_;
    
    $self->params($config,
	{
	    DESK => 0,
	    PAGEX => 0,
	    PAGEY => 0,
	    LAYOUT => 'None',
	    MAX_WIN=>1,
	})
	|| return undef;

    $self->{groups} = {};
    return $self;
} # init

=head2 num_windows

How many windows?

=cut
sub num_windows {
    my $self = shift;

    my $num = int (@{$self->{windows}});
    return $num;
} # num_windows

=head2 window

Return the given window.
$grp = $self->window($index);

=cut
sub window {
    my $self = shift;
    my $ind = shift;

    if (!@{$self->{windows}})
    {
	return $self->error("No windows");
    }
    if ($ind >= @{$self->{windows}} or $ind < 0)
    {
	return $self->error("Index $ind out of range");
    }
    my $win = $self->{windows}[$ind];
    return $win;
} # window

=head1 REQUIRES

    Class::Base

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot org
    http://www.katspace.com/tools/fvwm_tiler/

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2009 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of FvwmLayout::Page
__END__
