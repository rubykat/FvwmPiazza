package FvwmLayout::Layouts::Rows;
use strict;
use warnings;

=head1 NAME

FvwmLayout::Layouts::Rows - Rows layout.

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Rows" layout for FvwmLayout.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use FvwmLayout::Tiler;
use FvwmLayout::Page;
use FvwmLayout::Group;
use FvwmLayout::GroupWindow;

use base qw( FvwmLayout::Layouts );

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
		max_win=>2,
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

    my $num_rows = $args{max_win};
    my $num_win = $area->num_windows();

    if ($num_win == 0)
    {
	return $self->error("there are zero windows");
    }
    if ($num_win < $num_rows)
    {
	$area->redistribute_windows(n_groups=>$num_win);
	$num_rows = $num_win;
    }
    elsif ($area->num_groups() != $num_rows)
    {
	$area->redistribute_windows(n_groups=>$num_rows);
    }

    # Calculate the row heights
    # Don't apply the passed-in ratios if we have fewer rows
    # than the layout requires
    my @ratios = ();
    if ($num_rows == $args{max_win} and defined $options[0])
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_rows,
	    ratios=>$options[0]);
    }
    else
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_rows);
    }

    # Arrange the windows
    my $ypos = $args{top_offset};
    my $xpos = $args{left_offset};
    for (my $row_nr=0; $row_nr < $num_rows; $row_nr++)
    {
	my $row_height = int($working_height * $ratios[$row_nr]);
	my $group = $area->group($row_nr);
	$group->arrange_group(module=>$args{tiler},
			      x=>$xpos,
			      y=>$ypos,
			      width=>$working_width,
			      height=>$row_height);
	$ypos += $row_height;
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

1; # End of FvwmLayout::Layouts
__END__
