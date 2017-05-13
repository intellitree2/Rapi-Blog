package Rapi::Blog::Model::DB;
use Moo;
extends 'Catalyst::Model::DBIC::Schema';
with 'RapidApp::Util::Role::ModelDBIC';

use strict;
use warnings;

use Path::Class qw(file);
use RapidApp::Util ':all';
my $db_path = file( RapidApp::Util::find_app_home('Rapi::Blog'), 'rapi_blog.db' );
sub _sqlt_db_path { "$db_path" };    # exposed for use by the regen devel script

use Rapi::Blog::Util;

#<<<  tell perltidy not to mess with this
before 'setup' => sub {
  my $self = shift;

  # extract path from dsn because the app reaches in to set it
  my $dsn = $self->connect_info->{dsn};
  my ( $pre, $db_path ) = split( /\:SQLite\:/, $dsn, 2 );

  unless ( -f $db_path ) {
    warn "  ** Auto-Deploy $db_path **\n";
    $self->_one_off_connect->deploy;
  }

  my $diff =
    $self->_diff_deployed_schema
    ->filter_out('*:relationships')
    ->filter_out('*:constraints')
    ->filter_out('*:isa')
    ->filter_out('*:columns/*._inflate_info')
    ->filter_out('*:columns/*._ic_dt_method')
    ->diff;

  if ($diff) {
    die join( "\n",
      '', '', '', '**** ' . __PACKAGE__ . ' - column differences found in deployed database! ****',
      '', 'Dump (DBIx::Class::Schema::Diff): ',
      Dumper($diff), '', '', '' );
  }
};
#>>>

__PACKAGE__->config(
  schema_class => 'Rapi::Blog::DB',

  connect_info => {
    dsn             => "dbi:SQLite:$db_path",
    user            => '',
    password        => '',
    quote_names     => q{1},
    sqlite_unicode  => q{1},
    on_connect_call => q{use_foreign_keys},
  },

  # Configs for the RapidApp::RapidDbic Catalyst Plugin:
  RapidDbic => {

    # use only the relationship column of a foreign-key and hide the
    # redundant literal column when the names are different:
    hide_fk_columns => 1,

    # The grid_class is used to automatically setup a module for each source in the
    # navtree with the grid_params for each source supplied as its options.
    grid_class  => 'Rapi::Blog::Module::GridBase',
    grid_params => {
      # The special '*defaults' key applies to all sources at once
      '*defaults' => {
        include_colspec => ['*'],    #<-- default already ['*']
        ## uncomment these lines to turn on editing in all grids
        updatable_colspec   => ['*'],
        creatable_colspec   => ['*'],
        destroyable_relspec => ['*'],
        extra_extconfig     => {
          store_button_cnf => {
            save => { showtext => 1 },
            undo => { showtext => 1 }
          }
        }
      },
      Post => {
        page_class => 'Rapi::Blog::Module::PostPage'
      }
    },

    # TableSpecs define extra RapidApp-specific metadata for each source
    # and is used/available to all modules which interact with them
    TableSpecs => {
      Format => {
        display_column => 'name',
        title          => 'Format',
        title_multi    => 'Format Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          code => {
            header => 'code',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          contents => {
            header => 'contents',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          posts => {
            header => 'posts',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Keyword => {
        display_column => 'name',
        title          => 'Keyword',
        title_multi    => 'Keyword Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_keyword => {
            header => 'content_keyword',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_keyword => {
            header => 'post_keyword',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Post => {
        display_column => 'title',
        title_multi    => 'Posts',
        iconCls        => 'icon-post',
        multiIconCls   => 'icon-posts',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'id',
            width     => 80,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          title => {
            header => 'title',
            width  => 160,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          image => {
            header => 'image',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          create_ts => {
            header    => 'create_ts',
            allow_add => \0,
            allow_edit => \0,
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          update_ts => {
            header    => 'update_ts',
            allow_add => \0,
            allow_edit => \0,
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          pp_code => {
            header => 'pp_code',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          format_code => {
            header => 'format_code',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          published => {
            header => 'published',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          publish_ts => {
            header     => 'publish_ts',
            allow_add  => \0,
            allow_edit => \0,
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          body => {
            header => 'body',
            hidden => 1,
            width  => 400,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['markdown'],
          },
          post_keywords => {
            header => 'post_keywords',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          ts => {
            header => 'ts',
            # extra_properties get merged instead of replaced, so we don't clobber the rest of 
            # the 'editor' properties
            extra_properties => {
              editor => {
                value => sub { Rapi::Blog::Util->now_ts }
              }
            }
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          author_id => {
            header => 'author_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          creator_id => {
            header => 'creator_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          updater_id => {
            header => 'updater_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          author => {
            header => 'author',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
            editor => {
              value => sub {
                return 0;
              }
            }
          },
          creator => {
            header    => 'creator',
            allow_add => \0,
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          updater => {
            header    => 'updater',
            allow_add => \0,
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      PostKeyword => {
        display_column => 'id',
        title          => 'PostKeyword',
        title_multi    => 'PostKeyword Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_id => {
            header => 'post_id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            profiles => ['hidden'],
          },
          keyword_name => {
            header => 'keyword_name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post => {
            header => 'post',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      Preprocessor => {
        display_column => 'name',
        title          => 'Preprocessor',
        title_multi    => 'Preprocessor Rows',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          code => {
            header => 'code',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          name => {
            header => 'name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          contents => {
            header => 'contents',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          posts => {
            header => 'posts',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
      User => {
        display_column => 'username',
        title          => 'User',
        title_multi    => 'Users',
        iconCls        => 'ra-icon-pg',
        multiIconCls   => 'ra-icon-pg-multi',
        columns        => {
          id => {
            allow_add => 0,
            header    => 'id',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          username => {
            header => 'username',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          full_name => {
            header => 'full_name',
            #width => 100,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_create_users => {
            header => 'content_create_users',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          content_update_users => {
            header => 'content_update_users',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_create_users => {
            header => 'post_create_users',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_update_users => {
            header => 'post_update_users',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_authors => {
            header => 'post_authors',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_creators => {
            header => 'post_creators',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
          post_updaters => {
            header => 'post_updaters',
            #width => 100,
            #sortable => 1,
            #renderer => 'RA.ux.App.someJsFunc',
            #profiles => [],
          },
        },
      },
    }
  },

);

=head1 NAME

Rapi::Blog::Model::DB - Catalyst/RapidApp DBIC Schema Model

=head1 SYNOPSIS

See L<Rapi::Blog>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Rapi::Blog::DB>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema::ForRapidDbic - 0.65

=head1 AUTHOR

root

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
