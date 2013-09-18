package ImprovedFavorites::Plugin;

use strict;
sub hdlr_entryfavoritedby {
	# This function puts each author that has favorited the current entry in context inside
	# of the 'EntryFavoritedBy' loop tag
	my ($ctx, $args, $cond) = @_;
	require MT::ObjectScore;
	require MT::Entry;
	require MT::App::Community;     
	
	# Check if there is actually an entry in context...
	my $entry = $ctx->stash('entry')
        || $ctx->error(MT->translate('You used an [_1] tag outside of the proper context.', 'EntryFavoritedBy'));
        
        # Load the authors that have favorited this entry
        my @authors = MT::Author->load({}, {join => MT::ObjectScore->join_on('author_id',{
        		object_id => $entry->id,
        		object_ds => MT::Entry->datasource,
        		namespace => MT::App::Community->NAMESPACE(),
                },
                {
                	unique    => 1,
        })});   
        
        # Generate output by putting each author in the current context and building the template
        # code that is inside the loop with it
        my $out;
        foreach my $author (@authors){
        	$ctx->{__stash}{author} = $author;
        	
        	my $tokens = $ctx->stash('tokens');
        	my $builder = $ctx->stash('builder');
        	
        	$out .= $builder->build( $ctx, $tokens, $cond)
        	|| return $ctx->error( $builder->errstr );
        }      
        return $out;
}

sub hdlr_unregisteredfavoritecount {
	# This function returns the number of favorites on an entry made by unregistered users
	my ($ctx, $args, $cond) = @_;
	require MT::ObjectScore;
	require MT::Entry;
	require MT::App::Community;     
	
	# Check if there is actually an entry in context...
	my $entry = $ctx->stash('entry')
        || $ctx->error(MT->translate('You used an [_1] tag outside of the proper context.', 'EntryFavoritedBy'));
        
        
        my $count = 0;
        
        # Load the anonymous authors that have favorited this entry
       $count = MT::ObjectScore->count({
       		       'author_id' => 0, 
       		       object_id => $entry->id,
       		       object_ds => MT::Entry->datasource,
       		       namespace => MT::App::Community->NAMESPACE()
       });
       MT->log('Count : '.$count);
        
        return $count;
}


sub objectscore_post_save {
	# This callback function gets called every time an objectscore object is saved
	# If the objectscore refers to an entry, rebuild the entry in question +
	# indexes
	my ($cb, $objectscore) = @_;
	if ($objectscore->object_ds eq "entry"){
		require MT::Entry;
		my $entry = MT::Entry->load($objectscore->object_id);
		MT->rebuild_entry( {Entry => $entry, BuildDependencies => 1});
		MT->rebuild_indexes( BlogID => $entry->blog_id);
	}
}


1; # Every module must return true
