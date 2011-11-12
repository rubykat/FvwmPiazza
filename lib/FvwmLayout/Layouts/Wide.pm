use strict;
use warnings;
package FvwmLayout::Layouts::Wide;

=head1 NAME

FvwmLayout::Layouts::Wide - Wide layout.

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Wide" layout for FvwmLayout.
One "wide" row and the rest of the windows in the other row.

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

    my $num_win = $area->num_windows();
    my $max_win = $args{max_win};

    my $num_rows = 2;
    $num_rows = 1 if $num_win == 1;
    my $wide_style = ($args{variant} ? $args{variant} : '');
    my $wide_row_nr = ($wide_style =~ /Bottom/i ? 1 : 0);
    my $width_ratio = '';
    my $height_ratio = '';
    if (defined $args{ratios})
    {
	my @rat = split(',', $args{ratios});
	$width_ratio = $rat[0];
	$height_ratio = $rat[1];
    }

    # adjust the max-win if we have few windows
    if ($num_win < $max_win)
    {
	$max_win = $num_win;
    }
    my $num_cols = $max_win - 1;
    $num_cols = 1 if $num_cols <= 0;

    # Calculate the width and height ratios
    my @width_ratios =
	$self->calculate_ratios(num_sets=>$num_cols, ratios=>$width_ratio);
    my @height_ratios =
	$self->calculate_ratios(num_sets=>$num_rows, ratios=>$height_ratio);

    my $col_nr = 0;
    my $row_nr = 0;
    my $xpos = 0;
    my $ypos = 0;
    if (!$self->{VIEWPORT_POS_BUG})
    {
	$xpos = $work_area->{wa_x};
	$ypos = $work_area->{wa_y};
    }
    for (my $i=0; $i < $area->num_windows(); $i++)
    {
	my $win = $area->window($i);
	my $col_width = int($working_width * $width_ratios[$col_nr]);
	my $row_height = int($working_height * $height_ratios[$row_nr]);

	if ($row_nr == $wide_row_nr)
	{
	    $self->arrange_window(module=>$args{tiler},
		wid=>$win->{id},
		x=>($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x}),
		y=>$ypos,
		width=>$working_width,
		height=>$row_height);
	    $args{tiler}
	    ->debug("wide_row_nr=$wide_row_nr row_height=$row_height");
	}
	else
	{
	    $self->arrange_window(module=>$args{tiler},
		wid=>$win->{id},
		x=>$xpos,
		y=>$ypos,
		width=>$col_width,
		height=>$row_height);
	    $args{tiler}
	    ->debug("col=$col_nr, row=$row_nr, xpos=$xpos, ypos=$ypos");
	}

	if ($row_nr == $wide_row_nr)
	{
	    $row_nr++;
	    $col_nr = 0;
	    $xpos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x});
	    $ypos += $row_height;
	}
	else
	{
	    $col_nr++;
	    $xpos += $col_width;
	    if ($col_nr >= $num_cols)
	    {
		$col_nr = 0;
		$xpos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x});
		$row_nr++;
		$ypos += $row_height;
	    }
	}
	if ($row_nr >= $num_rows)
	{
	    $col_nr = 0;
	    $row_nr = 0;
	    $xpos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x});
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

    my $working_width = $work_area->{wa_width};
    my $working_height = $work_area->{wa_height};
    my $wid = $args{wid};
    my $window = $area->window_by_id($wid);

    my $num_win = $area->num_windows();
    my $max_win = $args{max_win};

    my $num_rows = 2;
    $num_rows = 1 if $num_win == 1;
    my $wide_style = ($args{variant} ? $args{variant} : '');
    my $wide_row_nr = ($wide_style =~ /Bottom/i ? 1 : 0);
    my $width_ratio = '';
    my $height_ratio = '';
    if (defined $args{ratios})
    {
	my @rat = split(',', $args{ratios});
	$width_ratio = $rat[0];
	$height_ratio = $rat[1];
    }

    # adjust the max-win if we have few windows
    if ($num_win < $max_win)
    {
	$max_win = $num_win;
    }
    my $num_cols = $max_win - 1;
    $num_cols = 1 if $num_cols <= 0;

    # Calculate the width and height ratios
    my @width_ratios =
	$self->calculate_ratios(num_sets=>$num_cols, ratios=>$width_ratio);
    my @height_ratios =
	$self->calculate_ratios(num_sets=>$num_rows, ratios=>$height_ratio);

    # Calculate the centre point of this window
    my $centre_x = $window->{x} + ($window->{width} / 2);
    my $centre_y = $window->{y} + ($window->{height} / 2);

    my $col_nr = 0;
    my $row_nr = 0;
    my $xpos = 0;
    my $ypos = 0;
    if (!$self->{VIEWPORT_POS_BUG})
    {
	$xpos = $work_area->{wa_x};
	$ypos = $work_area->{wa_y};
    }
    my $placed = 0;
    while (!$placed and $col_nr < $num_cols)
    {
	my $col_width = int($working_width * $width_ratios[$col_nr]);
	my $row_height = int($working_height * $height_ratios[$row_nr]);

	if ($centre_y > $ypos
		and $centre_y < ($ypos + $row_height))
	{
	    if ($row_nr == $wide_row_nr)
	    {
		$self->arrange_window(module=>$args{tiler},
		    wid=>$window->{id},
		    x=>($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x}),
		    y=>$ypos,
		    width=>$working_width,
		    height=>$row_height);
		$args{tiler}
		->debug("wide_row_nr=$wide_row_nr row_height=$row_height");
		$placed = 1;
		last;
	    }
	    else
	    {
		if ($centre_x > $xpos
			and $centre_x < ($xpos + $col_width))
		{
		    $self->arrange_window(module=>$args{tiler},
			wid=>$window->{id},
			x=>$xpos,
			y=>$ypos,
			width=>$col_width,
			height=>$row_height);
		    $args{tiler}
		    ->debug("col=$col_nr, row=$row_nr, xpos=$xpos, ypos=$ypos");
		    $placed = 1;
		    last;
		}
	    }
	}

	if ($row_nr == $wide_row_nr)
	{
	    $row_nr++;
	    $col_nr = 0;
	    $xpos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x});
	    $ypos += $row_height;
	}
	else
	{
	    $col_nr++;
	    $xpos += $col_width;
	    if ($col_nr >= $num_cols)
	    {
		$col_nr = 0;
		$xpos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x});
		$row_nr++;
		$ypos += $row_height;
	    }
	}
	if ($row_nr >= $num_rows)
	{
	    $col_nr = 0;
	    $row_nr = 0;
	    $xpos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x});
	    $ypos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_y});
	}
    }
    if (!$placed)
    {
	$args{tiler}->debug("could not place window[$wid] ==== "
	    . " x=$window->{x}"
	    . " y=$window->{y}"
	    . " width=$window->{width}"
	    . " height=$window->{height}"
	    . " centre_x=$centre_x"
	    . " centre_y=$centre_y"
	);
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
