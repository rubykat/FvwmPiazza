package FvwmLayout::Layouts::Tall;
use strict;
use warnings;

=head1 NAME

FvwmLayout::Layouts::Tall - Tall layout.

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Tall" layout for FvwmLayout.
One "tall" column and the rest of the windows in the other column.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use FvwmLayout::Tiler;
use FvwmLayout::Page;

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
		work_area=>undef,
		options=>[],
		max_win=>2,
		tiler=>undef,
		@_
	       );
    if (!defined $args{area})
    {
	return $self->error("area not defined");
    }
    if (!defined $args{work_area})
    {
	return $self->error("work_area not defined");
    }
    if (!defined $args{tiler})
    {
	return $self->error("tiler not defined");
    }
    my $area = $args{area};
    my $work_area = $args{work_area};
    my @options = @{$args{options}};

    my $working_width = $work_area->{wa_width};
    my $working_height = $work_area->{wa_height};

    my $num_win = $area->num_windows();
    my $max_win = $args{max_win};

    if ($num_win == 0)
    {
	return $self->error("there are zero windows");
    }
    my $num_cols = 2;
    $num_cols = 1 if $num_win == 1;
    my $tall_style = (@options ? shift @options : '');
    my $tall_col_nr = ($tall_style =~ /Right/i ? 1 : 0);
    my $width_ratio = (@options ? shift @options : '');
    my $height_ratio = (@options ? shift @options : '');

    # adjust the max-win if we have few windows
    if ($num_win < $max_win)
    {
	$max_win = $num_win;
    }
    my $num_rows = $max_win - 1;
    $num_rows = 1 if $num_rows <= 0;

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

	if ($col_nr == $tall_col_nr)
	{
	    $self->arrange_window(module=>$args{tiler},
		wid=>$win->{id},
		x=>$xpos,
		y=>($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_y}),
		width=>$col_width,
		height=>$working_height);
	    $args{tiler}
	    ->debug("tall_col_nr=$tall_col_nr col_width=$col_width");
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

	if ($col_nr == $tall_col_nr)
	{
	    $col_nr++;
	    $row_nr = 0;
	    $ypos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_y});
	    $xpos += $col_width;
	}
	else
	{
	    $row_nr++;
	    $ypos += $row_height;
	    if ($row_nr == $num_rows)
	    {
		$row_nr = 0;
		$ypos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_y});
		$col_nr++;
		$xpos += $col_width;
	    }
	}
	if ($col_nr == $num_cols)
	{
	    $col_nr = 0;
	    $row_nr = 0;
	    $xpos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x});
	    $ypos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_y});
	}
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
