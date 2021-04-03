package Local::Template::Utils;
use v5.20;
use warnings;
use experimental qw(signatures);

use Exporter   qw(import);
use Encode     qw(decode);
use File::Spec::Functions;
use Mojo::JSON qw(decode_json);
use Mojo::Template;
use Mojo::URL;
use Mojo::Util qw(dumper);
use Time::Piece;

my $log = get_logger();

sub by_post_epoch { $b->{post_epoch} <=> $a->{post_epoch} }

sub config_defaults () {
	{
	template     => 'default',
	base_dir     => 'docs',
	template_dir => '_templates',
	default_test => 'abc',
	items_json   => 'docs/items.json',
	};
	}

sub default_paths () {
	qw( _templates );
	}

sub find_file ( $file, @paths ) {
	@paths = default_paths() unless @paths;

	my @files =
		grep { -e }
		map { catfile( $_, $file ) }
		@paths;

	$files[0];
	}

sub get_config ( $file = 'config.json' ) {
	my $hash = get_json( $file, {} );

	my %config = ( config_defaults()->%*, $hash->%* );

	\%config;
	}

sub get_epoch_time ( $date ) {
	# 2015-12-28 23:45:01
	Time::Piece->strptime( $date, "%Y-%m-%d %H:%M:%S" )->epoch
	}

sub get_items  ( $file = config_defaults()->{items_json} ) {
	get_json( $file, [] )
	}

sub get_json ( $file, $default = {} ) {
	unless( -e $file ) {
		$log->warn( "Could not get JSON from <$file>:. File is missing" );
		return $default;
		}
	decode_json( Mojo::File->new( $file )->slurp );
	}

sub get_logger () {
	state $rc = require Mojo::Log;
	state $logger = do {
		my $log = Mojo::Log->new;
		$log->format( sub ($time,$level,@lines) {
			join( "\n", map { "[$level] $_" } @lines ) . "\n";
			} );
		$log;
		};

	$logger;
	}

sub get_templater () {
	Mojo::Template
		->new
		->vars(1)
		->prepend(
			'use lib qw(lib); use Local::Template::Utils; use Mojo::Template::Sandbox; our $vars;'
			);
	}


sub local_path ( $file, $headers ) {
	if( length $headers->{link} ) {
		my $url = Mojo::URL->new( $headers->{link} );
		my $path = $url->path;
		$path =~ s|\A /||rx;
		}
	else {
		my( $year, $month, $day, $title ) = split /-/, $file, 4;
		my $path = join '/', $year, $month, $day, $title;
		}
	}

sub parse_header ( $header ) {
	open my $sh, '<', \ $header;
	my %hash;
	while( <$sh> ) {
		chomp;
		my( $field, $value ) = split /:\s*/, $_, 2;
		$hash{$field} = $value;
		}
	return \%hash;
	}

sub rot13 ( $text ) { $text =~ tr/a-zA-Z/n-za-mN-ZA-M/r }

sub slurp ( $path ) {
	return unless -e $path;
	decode( 'UTF-8', Mojo::File->new( $path )->slurp )
	}

sub split_doc ( $file ) {
	my $data = slurp( $file );
	my( $header, $content ) = $data =~ m/ <!-- \R (.+?) \R --> \R \s* (.*) /sx;
	my $hash = parse_header( $header );
	return ( $hash, $content );
	}


our @EXPORT;
BEGIN {
	no strict 'refs';
	foreach my $name ( keys %{ __PACKAGE__ . '::' } ) {
		next unless defined &{$name};
		push @EXPORT, $name;
		}
	}

1;
