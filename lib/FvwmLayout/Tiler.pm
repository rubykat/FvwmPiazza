use strict;
package FvwmLayout::Tiler;

=head1 NAME

FvwmLayout::Tiler - Fvwm module for tiling windows.

=head1 SYNOPSIS

    use FvwmLayout::Tiler;

    my $obj = FvwmLayout::Tiler->new(\%args);

    ---------------------------------

    *FvwmLayout: Exclude (Gimp|feh)
    *FvwmLayout: UseMaximize true

    Key	f   A	MS  FvwmLayout --layout Full

=head1 DESCRIPTION

This tiles windows in different ways.

=cut

use lib `fvwm-perllib dir`;

use FVWM::Module;
use version;
use YAML::Any;
use FvwmLayout::Page;

use base qw( FVWM::Module );

use Module::Pluggable search_path => 'FvwmLayout::Layouts',
    sub_name => 'layouts', instantiate => 'new';

=head1 METHODS

=head2 new

=cut
sub new {
    my $class = shift;
    my %params = (
	@_
    );

    my $self = $class->SUPER::new(
	Name => "FvwmLayout",
	Mask => M_WINDOW_NAME | M_END_WINDOWLIST,
	EnableAlias => 0,
	Debug => 1,
	);
    bless $self, $class;

    $self->init(%params);
    return $self;
} # new

=head2 init

=cut

sub init {
    my $self = shift;
    my %params = (
	@_
    );
    while (my ($key, $val) = each(%params))
    {
	$self->{$key} = $val;
    }

    $self->{configTracker} = $self->track('ModuleConfig',
		DefaultConfig => {
		Include => '',
		Exclude => '',
		UseMaximize => 0,
	},
    );
    $self->{pageTracker} = $self->track("PageInfo");
    $self->{winTracker} = $self->track("WindowList");

    # In Fvwm version 2.6.3, the behaviour of "Move" commands
    # changed so that they honoured EWMH-struts.
    # For previous versions, we have to do the strut-checking ourselves.
    my $fvwm_version = version->parse($self->version());
    my $move_honours_struts = ($fvwm_version >= version->parse("2.6.3"));

    $self->{Layouts} = {};
    foreach my $lay ($self->layouts())
    {
	$self->debug("Layout: " . ref $lay);
	$self->{Layouts}->{$lay->name()} = $lay;
	$self->{Layouts}->{$lay->name()}->{MOVE_HONOURS_STRUTS} = $move_honours_struts;
	$self->{Layouts}->{$lay->name()}->{maximize} = $self->{configTracker}->data('UseMaximize');
    }

    $self->add_handler(M_WINDOW_NAME, sub {
	    my ($module, $event) = @_;
	    $self->handle_window_name($event);
	});
    $self->add_handler(M_END_WINDOWLIST, sub {
	    my ($module, $event) = @_;
	    $self->handle_end_windowlist($event);
	});

    return $self;
} # init

=head2 start

$self->start();

Start the event loop.

=cut
sub start {
    my $self = shift;

    if ($self->{layout} =~ /dump/i)
    {
	$self->debug("===============================\n"
	    . Dump($self)
	    . "---------------------\n");
	return 1;
    }
    $self->debug("layout=" . $self->{layout});

    # Ask fvwm to send us its list of windows
    $self->send("Send_WindowList");

    $self->eventLoop;
} # start

=head1 Handlers

=head2 handle_window_name

Get the next window in the window list.

=cut
sub handle_window_name {
    my $self = shift;
    my $event = shift;

    if (!defined $self->{_winlist})
    {
	$self->{_winlist} = [];
    }
    push @{$self->{_winlist}}, $event->_win_id;

} # handle_window_name

=head2 handle_end_windowlist

We've got to the end of the window-list - go for it!

=cut
sub handle_end_windowlist {
    my $self = shift;
    my $event = shift;

    $self->apply_tiling(layout=>$self->{layout});

    # We're done!
    # Terminate itself after 1 second
    # Give this delay to allow commands to finish.
    my $scheduler = $self->track('Scheduler');
    $scheduler->schedule(1, sub { $self->terminate; });
} # handle_end_windowlist

=head1 Helper methods

=head2 apply_tiling

Apply the requested tiling layout.

=cut
sub apply_tiling {
    my $self = shift;
    my %args = (
		layout=>'Full',
		args=>'',
		@_
	       );

    my $desk = $self->{pageTracker}->data->{desk_n};
    my $pagex = $self->{pageTracker}->data->{page_nx};
    my $pagey = $self->{pageTracker}->data->{page_ny};

    my $page_info = $self->get_current_page_data();

    my $layout = $args{layout};
    $self->debug("layout=$layout : $args{args}");

    my $vp_width = $self->{pageTracker}->data->{'vp_width'};
    my $vp_height = $self->{pageTracker}->data->{'vp_height'};
    my %work_area = $self->get_workarea();

    if (exists $self->{Layouts}->{$layout}
	and defined $self->{Layouts}->{$layout})
    {
	if ($self->{wid})
	{
	    $self->{Layouts}->{$layout}->place_window(
		area=>$page_info,
		work_area=>\%work_area,
		wid=>$self->{wid},
		max_win=>$self->{maxwin},
		rows=>$self->{rows},
		cols=>$self->{cols},
		ratios=>$self->{ratios},
		variant=>$self->{variant},
		options=>$self->{options},
		tiler=>$self,
	    );
	}
	else
	{
	    $self->{Layouts}->{$layout}->apply_layout(
		area=>$page_info,
		work_area=>\%work_area,
		max_win=>$self->{maxwin},
		rows=>$self->{rows},
		cols=>$self->{cols},
		ratios=>$self->{ratios},
		variant=>$self->{variant},
		options=>$self->{options},
		tiler=>$self,
	    );
	}
    }

} # apply_tiling

=head2 get_current_page_data

Initialize page information for the current page.

=cut
sub get_current_page_data {
    my $self = shift;
    my %args = (
		desk_n=>$self->{pageTracker}->data->{desk_n},
		page_x=>$self->{pageTracker}->data->{page_nx},
		page_y=>$self->{pageTracker}->data->{page_ny},
		@_
	       );

    my $desk_n = $args{desk_n};
    my $pagex = $args{page_x};
    my $pagey = $args{page_y};
    $desk_n = 0 if !defined $desk_n;
    $pagex = 0 if !defined $pagex;
    $pagey = 0 if !defined $pagey;
    my $page_data =
    FvwmLayout::Page->new(DESK=>$desk_n,
	PAGEX=>$pagex,
	PAGEY=>$pagey,
	LAYOUT=>'None');
    my %page_windows = $self->get_page_windows(desk=>$desk_n,
	pagex=>$pagex,
	pagey=>$pagey);

    my @windows = ();
    foreach my $wid (@{$self->{_winlist}})
    {
	if (exists $page_windows{$wid})
	{
	    my $pwin = $page_windows{$wid};
	    $self->debug("==== $wid - '" .  $pwin->{name} . "'");
	    push @windows, $pwin;
	}
    }
    $page_data->{windows} = \@windows;
    return $page_data;
} # get_current_page_data

=head2 check_interest

Look at the properties of the given window to see if we are interested in it.
We aren't interested in SKIP_PAGER, SKIP_TASKBAR, DOCK or Withdrawn windows.
We also aren't interested in transient windows.

Also, we may not be interested in windows of certain classes or names.

$res = $self->check_interest(window=>$id, tracker=>$tracker);

$res = $self->check_interest(window=>$id, event=>$event);

=cut
sub check_interest {
    my $self = shift;
    my %args = (
		window=>undef,
		tracker=>undef,
		event=>undef,
		@_
	       );
    if (!defined $args{window} or !$args{window})
    {
	return 0;
    }
    my $wid;
    my $window;
    if (ref $args{window} eq "FVWM::Window")
    {
	$window = $args{window};
	$wid = $window->{id};
    }
    my $interest = 1;
    my $include = ($self->{include} ? $self->{include} : $self->{configTracker}->data('Include'));
    my $exclude = ($self->{exclude} ? $self->{exclude} : $self->{configTracker}->data('Exclude'));
    my @names = ();
    open (XPROP, "xprop -id $wid |") or die "Could not start xprop";
    while (<XPROP>)
    {
	if (/_NET_WM_WINDOW_TYPE_DOCK/
	    or /_NET_WM_STATE_SKIP_PAGER/
	    or /_NET_WM_STATE_SKIP_TASKBAR/
	    or /_NET_WM_WINDOW_TYPE_DIALOG/
	    or /window state: Withdrawn/
	    or /_NET_WM_STATE_STICKY/
	    or /_NET_WM_WINDOW_TYPE_DIALOG/
	    or /WM_TRANSIENT_FOR/
	    or /_NET_WM_WINDOW_TYPE_SPLASH/
	    or /_NET_WM_WINDOW_TYPE_DESKTOP/
	    or /_NET_WM_WINDOW_TYPE_MENU/
	)
	{
	    $interest = 0;
	    $self->debug(sprintf("No interest in 0x%x because %s", $wid, $_));
	    last;
	}
	# if we are including or excluding, then remember the class and names
	if (($exclude or $include)
	    and (/WM_CLASS/
		 or /WM_ICON_NAME/
		 or /WM_NAME/)
	   )
	{
	    if (/=\s*(.*)/)
	    {
		push @names, $1;
	    }

	}
    }
    close XPROP;
    # check the names, if we are interested
    if ($interest and @names)
    {
	# if we aren't checking includes, everything is included
	my $included = ($include ? 0 : 1);
	my $excluded = 0;
	foreach my $name (@names)
	{
	    if ($include and $name =~ /$include/i)
	    {
		$included = 1;
	    }
	    if ($exclude and $name =~ /$exclude/i)
	    {
		$excluded = 1;
		$self->debug(sprintf("No interest in 0x%x because excluding '%s'", $wid, $name));
	    }
	}
	if (!$included or $excluded)
	{
	    $interest = 0;
	}
    }

    return $interest;
} # check_interest

=head2 get_workarea

Get the current EWMH work-area.

=cut
sub get_workarea {
    my $self = shift;
    my %args = (
		@_
	       );
    open (XPROP, "xprop -root |") or die "Could not start xprop";
    my %props;
    while (<XPROP>)
    {
	if (/_NET_WORKAREA\(CARDINAL\) = (\d+), (\d+), (\d+), (\d+)/)
	{
	    $props{wa_x} = $1;
	    $props{wa_y} = $2;
	    $props{wa_width} = $3;
	    $props{wa_height} = $4;
	}
	elsif (/_NET_DESKTOP_GEOMETRY\(CARDINAL\) = (\d+), (\d+)/)
	{
	    $props{desk_width} = $1;
	    $props{desk_height} = $2;
	}
    }
    close XPROP;

    return %props;
} # get_workarea

=head2 dump_properties

Dump the properties of the given window.

=cut
sub dump_properties {
    my $self = shift;
    my %args = (
		window=>undef,
		@_
	       );
    my $wid = $args{window};
    open (XPROP, "xprop -id $wid |") or die "Could not start xprop";
    while (<XPROP>)
    {
	$self->debug("$_");
    }
    close XPROP;

} # dump_properties

=head2 get_page_windows

Get the windows on the given page.

=cut
sub get_page_windows {
    my $self = shift;
    my %args = (
		desk=>undef,
		pagex=>undef,
		pagey=>undef,
		@_
	       );

    # Find all the windows on this page
    my %page_windows = ();
    my $windata = $self->{winTracker}->data();
    while (my ($id, $window) = each %{$windata})
    {
	next unless $window->match("CurrentPage");
	next unless $window->match("!Iconified");
	next unless $window->match("!Transient");
	next unless $window->match("Maximizable");
	if (defined $window->{name})
	{
	    $self->debug("\t$id - " . $window->{name});
	}
	next unless $self->check_interest(window=>$window);

	$page_windows{$id} = $window;
    }
    return %page_windows;
} # get_page_windows

=head1 REQUIRES

    FVWM::Module
    Class::Base

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules.

Therefore you will need to change the PERL5LIB variable to add
/home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

perl(1).
fvwm(1)

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot org

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2009-2011 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of FvwmLayout::Tiler
__END__
