use strict;
use warnings;
package FvwmLayout::Layouts::Full;

=head1 NAME

FvwmLayout::Layouts::Full - Full layout.

=head1 SYNOPSIS

    $obj->apply_layout(%args);

=head1 DESCRIPTION

This defines the "Full" layout
for FvwmLayout.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use FvwmLayout::Tiler;
use FvwmLayout::Page;
use YAML::Any;

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
	max_win=>1,
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

    $args{tiler}->debug(
	" working_width=$working_width"
	. " working_height=$working_height"
	. " num_win=$num_win"
    );
    
    # Arrange the windows
    my $xpos = 0;
    my $ypos = 0;
    if (!$self->{MOVE_HONOURS_STRUTS})
    {
	$xpos = $work_area->{wa_x};
	$ypos = $work_area->{wa_y};
    }
    for (my $i=0; $i < $area->num_windows(); $i++)
    {
	my $win = $area->window($i);
	$args{tiler}->debug("window[$i] ===== " . $win->{name} . ' ' . $win->{id});
	$self->arrange_window(module=>$args{tiler},
	    wid=>$win->{id},
	    x=>$xpos,
	    y=>$ypos,
	    width=>$working_width,
	    height=>$working_height);
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
		max_win=>1,
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

    my $num_win = $area->num_windows();

    if ($num_win == 0)
    {
	return $self->error("there are zero windows");
    }
    
    # Arrange this window
    my $xpos = 0;
    my $ypos = 0;
    if (!$self->{MOVE_HONOURS_STRUTS})
    {
	$xpos = $work_area->{wa_x};
	$ypos = $work_area->{wa_y};
    }
    $self->arrange_window(module=>$args{tiler},
	wid=>$window->{id},
	x=>$xpos,
	y=>$ypos,
	width=>$working_width,
	height=>$working_height);

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
