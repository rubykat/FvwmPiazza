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

    my $working_width = $work_area->{wa_width};
    my $working_height = $work_area->{wa_height};

    my $num_rows = $args{max_win};
    my $num_win = $area->num_windows();

    if ($num_win == 0)
    {
	return $self->error("there are zero windows");
    }
    if ($num_win < $num_rows)
    {
	$num_rows = $num_win;
    }

    # Calculate the row heights
    # Don't apply the passed-in ratios if we have fewer rows
    # than the layout requires
    my @ratios = ();
    if ($num_rows == $args{max_win} and defined $args{ratios})
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
