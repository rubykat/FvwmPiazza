use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'FvwmTiler',
    license             => 'perl',
    dist_author         => 'Kathryn Andersen',
    dist_version_from   => 'lib/FvwmTiler/Tiler.pm',
	requires            => {
	     # module requirements here

	},
    build_requires => {
        'Test::More' => 0,
    },
    create_makefile_pl => 'traditional',
#    add_to_cleanup      => [ 'FvwmTiler-*' ],
);

$builder->create_build_script();
