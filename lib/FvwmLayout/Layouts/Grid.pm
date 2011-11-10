package FvwmLayout::Layouts::Grid;
use strict;
use warnings;

=head1 NAME

FvwmLayout::Layouts::Grid - Grid layout.

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Grid" layout for FvwmLayout.

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

    my $num_cols = (@options ? shift @options : 2);
    my $width_ratio = (@options ? shift @options : '');
    my $height_ratio = (@options ? shift @options : '');

    my $working_width = $work_area->{wa_width};
    my $working_height = $work_area->{wa_height};

    my $num_win = $area->num_windows();
    my $max_win = $args{max_win};

    if ($num_win == 0)
    {
	return $self->error("there are zero windows");
    }
    $num_cols = 1 if $num_win == 1;

    # adjust the max-win if we have few windows
    if ($num_win < $max_win)
    {
	$max_win = $num_win + ($num_win % $num_cols);
    }

    my $num_rows = int($max_win / $num_cols);

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
	my $row_height;

	my $windows_left = $area->num_windows() - $i;

	# If we have N windows left and N columns left
	# decrease the number of rows
	if ($windows_left <= ($num_cols - $col_nr)
		and $row_nr == 0
		and $num_win < $args{max_win})
	{
	    $num_rows = 1;
	    $row_height = $working_height;
	}
	else
	{
	    $row_height = int($working_height * $height_ratios[$row_nr]);
	}

	$self->arrange_window(module=>$args{tiler},
	    wid=>$win->{id},
	    x=>$xpos,
	    y=>$ypos,
	    width=>$col_width,
	    height=>$row_height);

	$row_nr++;
	$ypos += $row_height;
	if ($row_nr == $num_rows)
	{
	    $row_nr = 0;
	    $ypos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_y});
	    $col_nr++;
	    $xpos += $col_width;
	    if ($col_nr == $num_cols)
	    {
		$col_nr = 0;
		$xpos = ($self->{VIEWPORT_POS_BUG} ? 0 : $work_area->{wa_x});
	    }
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
