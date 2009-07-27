package FvwmTiler::Layouts::Tall;
use strict;
use warnings;

=head1 NAME

FvwmTiler::Layouts::Tall - Tall layout.

=head1 VERSION

This describes version B<0.01> of FvwmTiler::Layouts::Tall.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Tall" layout for FvwmTiler.
One "tall" column and the rest of the windows in the other column.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use FvwmTiler::Tiler;
use FvwmTiler::Page;
use FvwmTiler::Group;
use FvwmTiler::GroupWindow;

use base qw( FvwmTiler::Layouts );

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

    my $num_win = $area->num_windows();
    my $max_win = $args{max_win};

    if ($num_win == 0)
    {
	return $self->error("there are zero windows");
    }
    my $num_cols = 2;
    $num_cols = 1 if $num_win == 1;
    my $tall_col_nr = 0;
    if (defined $options[0] and $options[0] =~ /Right/)
    {
	$tall_col_nr = 1;
    }
    if ($num_win < $max_win)
    {
	$max_win = $num_win;
	$area->redistribute_windows(n_groups=>$max_win);
    }
    elsif ($area->num_groups() != $max_win)
    {
	$area->redistribute_windows(n_groups=>$max_win);
    }
    my $num_rows = $max_win - 1;
    $num_rows = 1 if $num_rows <= 0;

    my $col_width = int($working_width/$num_cols);
    my $row_height = int($working_height/$num_rows);
    $args{tiler}
    ->debug("Tall: max_win=$max_win, num_rows=$num_rows, col_width=$col_width, row_height=$row_height");
    my $col_nr = 0;
    my $row_nr = 0;
    for (my $gnr=0; $gnr < $max_win; $gnr++)
    {
	my $group = $area->group($gnr);

	my $xpos = $args{left_offset} + ($col_nr * $col_width);
	my $ypos = $args{top_offset} + ($row_nr * $row_height);
	if ($col_nr == $tall_col_nr)
	{
	    $group->arrange_group(module=>$args{tiler},
				  x=>$xpos,
				  y=>$args{top_offset},
				  width=>$col_width,
				  height=>$working_height);
	    $args{tiler}
	    ->debug("tall_col_nr=$tall_col_nr col_width=$col_width");
	}
	else
	{
	    $group->arrange_group(module=>$args{tiler},
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
	}
	else
	{
	    $row_nr++;
	    if ($row_nr == $num_rows)
	    {
		$row_nr = 0;
		$col_nr++;
	    }
	}
	if ($col_nr == $num_cols)
	{
	    $col_nr = 0;
	    $row_nr = 0;
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

1; # End of FvwmTiler::Layouts
__END__
