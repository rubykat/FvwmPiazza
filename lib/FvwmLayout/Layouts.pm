package FvwmLayout::Layouts;
use strict;
use warnings;

=head1 NAME

FvwmLayout::Layouts - Base class for FvwmLayout layouts.

=head1 SYNOPSIS

    use base qw(FvwmLayout::Layouts);

=head1 DESCRIPTION

This is the base class for defining different layout modules
for FvwmLayout.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use General::Parse;
use YAML::Syck;

use FvwmLayout::Tiler;

use base qw( Class::Base );

our $ERROR;
our $DEBUG = 0 unless defined $DEBUG;

=head2 name

The name of this layout.

=cut
sub name {
    my $self = shift;

    if (!$self->{NAME})
    {
	my $name = ref $self;
	$name =~ s/FvwmLayout::Layouts:://;
	$self->{NAME} = $name;
    }
    return $self->{NAME};
} # name

=head2 apply_layout

Apply the requested tiling layout.

=cut
sub apply_layout {
    my $self = shift;
    my %args = (
		@_
	       );

} # apply_layout

=head2 calculate_ratios

Calculate the desired ratios for lengths or widths.

=cut
sub calculate_ratios {
    my $self = shift;
    my %args = (
		num_sets=>1,
		ratios=>'',
		@_
	       );
    my $num_sets = $args{num_sets};

    my @ratios = ();
    if ($args{ratios}
	and $args{ratios} =~ /^([\d:]+)/)
    {
	my $ratio_str = $1;
	# The ratio arguments are in percent.
	my @r_args = split(':', $ratio_str);
	my $percent_left = 100;
	my $cols_left = $num_sets;
	for (my $i=0; $i < $num_sets; $i++)
	{
	    if ($i < @r_args)
	    {
		$ratios[$i] = $r_args[$i] / 100;
		$percent_left -= $r_args[$i];
		$cols_left--;
	    }
	    else
	    {
		$ratios[$i] = ($percent_left / $cols_left) / 100;
	    }
	}
    }
    else
    {
	for (my $i=0; $i < $num_sets; $i++)
	{
	    $ratios[$i] = 1/$num_sets;
	}
    }

    return @ratios;
} # calculate_ratios

=head2 arrange_window

Resize and move a window

$self->arrange_window(
wid=>$wid,
x=>$xpos,
y=>$ypos,
width=>$width,
height=>$height,
module=>$mod_ref,
);

=cut
sub arrange_window {
    my $self = shift;
    my %args = (
	wid=>undef,
	x=>undef,
	y=>undef,
	width=>undef,
	height=>undef,
	module=>undef,
	@_
    );
    # Even though we are calling this by window-id, add the window-id condition
    # to prevent a race condition (i hope)
    my $msg = "WindowId " . $args{wid} . " (Maximizable) ResizeMoveMaximize frame $args{width}p $args{height}p $args{x}p $args{y}p";
    $args{module}->debug($msg);
    $args{module}->send($msg, $args{wid});
} # arrange_window

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
