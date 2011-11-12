use strict;
use warnings;
package FvwmLayout::Layouts::Rows;

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

use base qw( FvwmLayout::Layouts );

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
		work_area=>undef,
		max_win=>2,
		tiler=>undef,
		@_
	       );
    my $err = $self->check_args(%args);
    if ($err)
    {
	return $self->error($err);
    }
    my $area = $args{area};
    my $work_area = $args{work_area};

    my $working_width = $work_area->{wa_width};
    my $working_height = $work_area->{wa_height};

    my $num_rows = ($args{max_win} ? $args{max_win}
	: ($args{rows} ? $args{rows} : 2));
    my $num_win = $area->num_windows();

    my $fewer = 0;
    if ($num_win < $num_rows)
    {
	$num_rows = $num_win;
	$fewer = 1;
    }

    # Calculate the row heights
    # Don't apply the passed-in ratios if we have fewer rows
    # than the layout requires
    my @ratios = ();
    if (!$fewer and defined $args{ratios})
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_rows,
	    ratios=>$args{ratios});
    }
    else
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_rows);
    }

    # Arrange the windows
    my $xpos = 0;
    my $ypos = 0;
    if (!$self->{VIEWPORT_POS_BUG})
    {
	$xpos = $work_area->{wa_x};
	$ypos = $work_area->{wa_y};
    }
    my $row_nr = 0;
    for (my $i=0; $i < $area->num_windows(); $i++)
    {
	my $win = $area->window($i);
	my $row_height = int($working_height * $ratios[$row_nr]);
	$self->arrange_window(module=>$args{tiler},
	    wid=>$win->{id},
	    x=>$xpos,
	    y=>$ypos,
	    width=>$working_width,
	    height=>$row_height);
	$row_nr++;
	$ypos += $row_height;
	if ($row_nr >= $num_rows)
	{
	    $row_nr = 0;
	    $ypos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_y});
	}
    }

} # apply_layout

=head2 place_window

Place one window within the tiling layout

=cut
sub place_window {
    my $self = shift;
    my %args = (
		area=>undef,
		work_area=>undef,
		max_win=>2,
		tiler=>undef,
		@_
	       );
    my $err = $self->check_args(%args);
    if ($err)
    {
	return $self->error($err);
    }
    my $area = $args{area};
    my $work_area = $args{work_area};
    my $wid = $args{wid};
    my $window = $area->window_by_id($wid);

    my $working_width = $work_area->{wa_width};
    my $working_height = $work_area->{wa_height};

    my $num_rows = ($args{max_win} ? $args{max_win}
	: ($args{rows} ? $args{rows} : 2));
    my $num_win = $area->num_windows();

    my $fewer = 0;
    if ($num_win < $num_rows)
    {
	$num_rows = $num_win;
	$fewer = 1;
    }

    # Calculate the row heights
    # Don't apply the passed-in ratios if we have fewer rows
    # than the layout requires
    my @ratios = ();
    if (!$fewer and defined $args{ratios})
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_rows,
	    ratios=>$args{ratios});
    }
    else
    {
	@ratios = $self->calculate_ratios(num_sets=>$num_rows);
    }

    # Calculate the centre point of this window
    my $centre_x = $window->{x} + ($window->{width} / 2);
    my $centre_y = $window->{y} + ($window->{height} / 2);

    # Arrange this window
    # Find the row which this window is nearest to.
    my $xpos = 0;
    my $ypos = 0;
    if (!$self->{VIEWPORT_POS_BUG})
    {
	$xpos = $work_area->{wa_x};
	$ypos = $work_area->{wa_y};
    }
    for (my $row_nr = 0; $row_nr < $num_rows; $row_nr++)
    {
	my $row_height = int($working_height * $ratios[$row_nr]);
	if ($centre_y > $ypos
		and $centre_y < ($ypos + $row_height))
	{
	    $self->arrange_window(module=>$args{tiler},
		wid=>$window->{id},
		x=>$xpos,
		y=>$ypos,
		width=>$working_width,
		height=>$row_height);
	    last;
	}
	$ypos += $row_height;
    }

} # place_window

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
