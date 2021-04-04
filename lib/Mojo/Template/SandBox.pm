package Mojo::Template::Sandbox;
use v5.20;
use experimental qw(signatures);

use Local::Template::Utils;

use Cwd qw(getcwd);
use Mojo::DOM;
use Mojo::Util qw(dumper);

our $vars;

=head2 Template things

=cut

BEGIN {
my @templates = qw(
	header footer styles sidebar menu page bottom middle article
	post page_div page_div_main_page middle_main_page excerpt_list
	items_div
	);
foreach my $template ( @templates ) {
	no strict 'refs';
	*{$template} = sub () { include( $template ) };
	}
}

sub include_raw ( $file ) { include( $file, 1 ) }

sub include ( $file, $raw = 0 ) {
	my $path = find_file( $file );
	my $contents = slurp( $path );
	return $contents if $raw;
	get_templater()->render( $contents );
	}

=head2 Manipulating variables

=over 4

=cut

sub set_vars   ( $hash = {} )   { $vars = $hash }
sub set_var    ( $key, $value ) { $vars->{$key} = $value }
sub get_var    ( $key )         { $vars->{$key} }
sub clear_vars ()               { $vars = {} }

sub dump_vars  ()               { delete local $vars->{content}; dumper( $vars ) }

=back

=head2 Variable things

=cut

sub cname { $vars->{config}{cname} }

sub content { $vars->{content} // '' }

sub excerpt ( $post ) {
	my $data = Mojo::File->new( $post->{local_path} )->slurp;
	my $dom  = Mojo::DOM->new($data);
	my $excerpt =
		   eval { $dom->at( 'div#content > span#excerpt' )->content  }
		// eval { $dom->at( 'div#content' )->content }
	    // '';
	$excerpt . '';
	}

sub recent_posts ( $count = 5 ) {
	state sub by_post_epoch { $b->{post_epoch} <=> $a->{post_epoch} }

	my $json = get_items( $vars->{config}{items_json} );
	say "There are " . $json->@* . " posts";
	my @posts =
		sort by_post_epoch
		grep { $_->{type} eq 'post' }
		$json->@*;

	@posts[0..$count-1];
	}

sub title { $vars->{title}   // '' }

1;
