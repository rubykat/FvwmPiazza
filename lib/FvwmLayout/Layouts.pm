package FvwmPiazza::Layouts;
use strict;
use warnings;

=head1 NAME

FvwmPiazza::Layouts - Base class for FvwmPiazza layouts.

=head1 SYNOPSIS

    use base qw(FvwmPiazza::Layouts);

=head1 DESCRIPTION

This is the base class for defining different layout modules
for FvwmPiazza.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use General::Parse;
use YAML::Syck;

use FvwmPiazza::Tiler;

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
	$name =~ s/FvwmPiazza::Layouts:://;
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
