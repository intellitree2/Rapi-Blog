package Rapi::Blog;

use strict;
use warnings;

# ABSTRACT: RapidApp-powered blog

use RapidApp 1.2111_64;

use Moose;
extends 'RapidApp::Builder';

use Types::Standard qw(:all);

use RapidApp::Util ':all';
use File::ShareDir qw(dist_dir);
use FindBin;
require Module::Locate;
use Path::Class qw/file dir/;
use YAML::XS 0.64 'LoadFile';

our $VERSION = '0.02';
our $TITLE = "Rapi::Blog v" . $VERSION;

has 'site_path',        is => 'ro', required => 1;
has 'scaffold_path',    is => 'ro', isa => Maybe[Str], default => sub { undef };
has 'scaffold_config',  is => 'ro', isa => HashRef, default => sub {{}};

has '+base_appname', default => sub { 'Rapi::Blog::App' };
has '+debug',        default => sub {1};

has 'share_dir', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;

  $ENV{RAPI_BLOG_SHARE_DIR} || (
    try{dist_dir('Rapi-Blog')} || (
      -d "$FindBin::Bin/share" ? "$FindBin::Bin/share"       : 
      -d "$FindBin::Bin/../share" ? "$FindBin::Bin/../share" :
      join('',$self->_module_locate_dir,'/../../share')
    )
  )
};

sub _module_locate_dir {
  my $self = shift;
  my $pm_path = Module::Locate::locate('Rapi::Blog') or die "Failed to locate Rapi::Blog?!";
  file($pm_path)->parent->stringify
}

has '+inject_components', default => sub {
  my $self = shift;
  my $model = 'Rapi::Blog::Model::DB';
  
  my $db = $self->site_dir->file('rapi_blog.db');
  
  Module::Runtime::require_module($model);
  $model->config->{connect_info}{dsn} = "dbi:SQLite:$db";

  return [
    [ $model => 'Model::DB' ],
    [ 'Rapi::Blog::Controller::Remote' => 'Controller::Remote' ]
  ]
};

has 'site_dir', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $Dir = dir( $self->site_path );
  -d $Dir or die "Scaffold directory '$Dir' not found.\n";
  
  return $Dir
}, isa => InstanceOf['Path::Class::Dir'];

has 'scaffold_dir', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $path = $self->scaffold_path || $self->site_dir->subdir('scaffold');
  
  my $Dir = dir( $path );
  -d $Dir or die "Scaffold directory '$Dir' not found.\n";
  
  return $Dir
}, isa => InstanceOf['Path::Class::Dir'];

has 'scaffold_cnf', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  
  my $defaults = {
    favicon            => 'favicon.ico',
    landing_page       => 'index.html',
    internal_post_path => 'private/post/',
    not_found          => 'rapidapp/public/http-404.html',
    view_wrappers      => [],
    static_paths       => ['/'],
    private_paths      => [],
    default_ext        => 'html',
  
  };
  
  my $cnf = clone( $self->scaffold_config );
  
  my $yaml_file = $self->scaffold_dir->file('scaffold.yml');
  if (-f $yaml_file) {
    my $data = LoadFile( $yaml_file );
    %$cnf = ( %$data, %$cnf );
  }
  
  %$cnf = ( %$defaults, %$cnf );
  
  return $cnf

}, isa => HashRef;

has 'default_view_path', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  return $self->scaffold_cnf->{default_view_path} if ($self->scaffold_cnf->{default_view_path});
  
  # first marked 'default' or first type 'include' or first anything
  my @wrappers = grep { $_->{path} } @{$self->scaffold_cnf->{view_wrappers} || []};
  my $def = List::Util::first { $_->{default} } @wrappers;
  $def ||= List::Util::first { $_->{type} eq 'include' } @wrappers;
  $def ||= $self->scaffold_cnf->{view_wrappers}[0];
  
  unless($def) {
    warn "\n ** Waring: scaffold has no suitable view_wrappers to use as 'default_view_path'\n\n";
    return undef;
  }

  return $def->{path}
};

has 'preview_path', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return $self->scaffold_cnf->{preview_path} || $self->default_view_path
};


sub _build_version { $VERSION }
sub _build_plugins { [qw/
  RapidApp::RapidDbic
  RapidApp::AuthCore
  RapidApp::NavCore
  RapidApp::CoreSchemaAdmin
/]}

sub _build_base_config {
  my $self = shift;
  
  my $tpl_dir = join('/',$self->share_dir,'templates');
  -d $tpl_dir or die join('',
    "template dir ($tpl_dir) not found; ", 
    __PACKAGE__, " may not be installed properly.\n"
  );
  
  my $loc_assets_dir = join('/',$self->share_dir,'assets');
  -d $loc_assets_dir or die join('',
    "assets dir ($loc_assets_dir) not found; ", 
    __PACKAGE__, " may not be installed properly.\n"
  );
  
  # Temp for dev/testing - everything but 'rapidapp/' templates:
  my $tpl_regex = '^(?!rapidapp\/).+';

  my $config = {
  
    'RapidApp' => {
      module_root_namespace => 'adm',
      local_assets_dir => $loc_assets_dir,
    },
    
    'Model::RapidApp::CoreSchema' => {
      sqlite_file => $self->site_dir->file('rapidapp_coreschema.db')->stringify
    },
    
    'Plugin::RapidApp::AuthCore' => {
      linked_user_model => 'DB::User'
    },
    
    'Controller::SimpleCAS' => {
      store_path => $self->site_dir->subdir('cas_store')->stringify
    },
    
    'Plugin::RapidApp::TabGui' => {
      title => $TITLE,
      nav_title => 'Administration',
      banner_template => file($tpl_dir,'banner.html')->stringify,
      dashboard_url => '/tpl/dashboard.md',
      #template_navtree_regex => $tpl_regex
    },
    
    'Controller::RapidApp::Template' => {
      root_template_prefix  => '/',
      root_template         => $self->scaffold_cnf->{landing_page},
      read_alias_path => '/tpl',  #<-- already the default
      edit_alias_path => '/tple', #<-- already the default
      default_template_extension => undef,
      include_paths => [ $tpl_dir ],
      access_class => 'Rapi::Blog::Template::AccessStore',
      access_params => {
        #writable_regex      => $tpl_regex,
        #creatable_regex     => $tpl_regex,
        #deletable_regex     => $tpl_regex,
        
        scaffold_dir  => $self->scaffold_dir,
        scaffold_cnf  => $self->scaffold_cnf,
        static_paths  => $self->scaffold_cnf->{static_paths},
        private_paths => $self->scaffold_cnf->{private_paths},
        default_ext   => $self->scaffold_cnf->{default_ext},
        
        internal_post_path => $self->scaffold_cnf->{internal_post_path},
        view_wrappers      => $self->scaffold_cnf->{view_wrappers},
        default_view_path  => $self->default_view_path,
        preview_path       => $self->preview_path,

        get_Model => sub { $self->base_appname->model('DB') } 
      } 
    }
  };
  
  if(my $favname = $self->scaffold_cnf->{favicon}) {
    my $Fav = $self->scaffold_dir->file($favname);
    $config->{RapidApp}{default_favicon_url} = $Fav->stringify if (-f $Fav);
  }
  
  
  return $config
}

1;
