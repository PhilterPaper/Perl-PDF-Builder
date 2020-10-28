use strict;
use warnings;
use File::Spec;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    plan( skip_all =>
          'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.' );
}

if ( not eval { require Test::Perl::Critic; } ) {
    plan( skip_all => 'Test::Perl::Critic required to criticise code' );
}

Test::Perl::Critic->import(
    -profile => File::Spec->catfile( 't', 'perlcriticrc' ) );
all_critic_ok( 'contrib', 'examples', 'lib', 'tools' );
