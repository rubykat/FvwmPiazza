package FvwmPiazza::Layouts::Full;
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Layouts::Full - Full layout.

=head1 VERSION

This describes version B<0.01> of FvwmPiazza::Layouts::Full.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Full" layout
for FvwmPiazza.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use FvwmPiazza::Tiler;
use FvwmPiazza::Page;
use FvwmPiazza::Group;
use FvwmPiazza::GroupWindow;

use base qw( FvwmPiazza::Layouts );

our $ERROR;
our $DEBUG = 0 unless defined $DEBUG;

=head1 METHODS

=head2 init

=cut

sub init {
    my ($self, $config) = @_;

    return $self;
} # init


=head2 apply_layout

Apply the requested tiling layout.

=cut
sub apply_layout {
    my $self = shift;
    my %args = (
		area=>undef,
		options=>[],
		left_offset=>0,
		right_offset=>0,
		top_offset=>0,
		bottom_offset=>0,
		vp_width=>0,
		vp_heigt=>0,
		max_win=>1,
		tiler=>undef,
		@_
	       );
    if (!defined $args{area})
    {
	return $self->error("area not defined");
    }
    if (!defined $args{tiler})
    {
	return $self->error("tiler not defined");
    }
    if ($args{vp_width} == 0)
    {
	return $self->error("vp_width is zero");
    }
    if ($args{vp_height} == 0)
    {
	return $self->error("vp_height is zero");
    }
    my $area = $args{area};
    my @options = @{$args{options}};

    my $working_width = $args{vp_width} -
	($args{left_offset} + $args{right_offset});
    my $working_height = $args{vp_height} -
	($args{top_offset} + $args{bottom_offset});

    my $max_win = $args{max_win};
    my $num_win = $area->num_windows();

    if ($num_win == 0)
    {
	return $self->error("there are zero windows");
    }
    if ($area->num_groups() != $max_win)
    {
	$area->redistribute_windows(n_groups=>$max_win);
    }
    if ($area->num_groups() == 0)
    {
	return $self->error("there are zero groups");
    }
    
    # Arrange the windows
    my $ypos = $args{top_offset};
    my $xpos = $args{left_offset};
    for (my $grp=0; $grp < $area->num_groups(); $grp++)
    {
	my $group = $area->group($grp);
	$group->arrange_group(module=>$args{tiler},
	    x=>$xpos,
	    y=>$ypos,
	    width=>$working_width,
	    height=>$working_height);
    }

} # apply_layout

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

1; # End of FvwmPiazza::Layouts
__END__
