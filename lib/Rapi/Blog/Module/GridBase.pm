package Rapi::Blog::Module::GridBase;

use strict;
use warnings;

use Moose;
extends 'Catalyst::Plugin::RapidApp::RapidDbic::TableBase';

use RapidApp::Util ':all';
use Rapi::Blog::Util;

sub BUILD {
  my $self = shift;
  
  if($self->ResultSource->source_name eq 'Post') {

    $self->apply_extconfig(
      reload_on_show => \1,
      autoload_added_record => \1,
      store_button_cnf => {
        add => {
          text     => 'New Post',
          iconCls  => 'icon-post-add',
          showtext => 1
        }
      },
    );
  }
}

has '+use_edit_form', default => 0;

around 'get_add_form' => sub {
  my ($orig, $self, @args) = @_;
  
  return {
    %{$self->$orig(@args)},
    autoScroll => \0,
    bodyStyle => 'padding: 0px;',
  }
};

around 'get_add_edit_form_items' => sub {
  my ($orig, $self, @args) = @_;
  
  my @items = $self->$orig(@args);

  if($self->ResultSource->source_name eq 'Post') {

    my @sets = (
    
      $self->_collect_to_fieldset(
        \@items, [qw/name title author ts published/], {
          width => 400,
          title => 'Attributes',
          labelWidth => 60
      }),

      $self->_collect_to_fieldset(
        \@items, [qw/image/], {
          width => 150,
          title => 'Image',
      },{hideLabel => \1}), 
      
      $self->_collect_to_fieldset(
        \@items, [qw/custom_summary/], {
          width => 400,
          title => join('',
            'Custom Summary ',
            '<span style="font-size:.9em;">',
              '(leave blank for auto-generated summary)',
            '</span>'),
      },{hideLabel => \1, growMax => 110, growMin => 110, anchor => '-5' })
    );
    
    my $wrap = {
      xtype => 'fieldset',
      layout => 'hbox',
      anchor => '100%',
      hideBorders => \1,
      collapsible => \1,
      items => \@sets
    };
    
    my $disp = {
      xtype => 'label',
      html => join('',
        '<div class="rabl-add-form-body-label">',
          '<span class="main">Post body:</span>',
          '<span class="hashtag">(enter Tags in Twitter-style <i>#Hashtag</i> format)</span>',
          '<span class="format">Markdown/HTML</span>',
        '</div>'
      )
    };
    
    @items = ($wrap,$disp,@items);
    
    my $eF = $items[$#items] || {}; # last element
    if($eF->{xtype} eq 'ra-md-editor') {
      $eF->{_noAutoHeight} = 1;
      $eF->{plugins} = 'ra-parent-gluebottom';
      $eF->{hideLabel} = \1;
      $eF->{anchor} = '100%';
    }
  }

  return @items;
};



sub _collect_to_fieldset {
  my ($self, $items, $cols, $opt, $ovr) = @_;
  
  my %colndx = map {$_=>1} @$cols;
  my %pulled = ();
  my @remaining = ();
  for my $itm (@$items) {
    $colndx{$itm->{name}} 
      ? $pulled{$itm->{name}} = $itm
      : push @remaining, $itm
  }
  
  @$items = @remaining;
  
  if($ovr) {
    $pulled{$_} = { %{$pulled{$_}}, %$ovr } for (keys %pulled);
  }
  
  my @f_items = map { $pulled{$_} || () } @$cols;
  
  return {
    xtype => 'fieldset',
    #style => 'float:left;margin-right:10px;',
  
    %{$opt||{}},
    items => \@f_items
  }
}




before 'load_saved_search' => sub { (shift)->apply_permissions };

sub apply_permissions {
  my $self = shift;
  my $c = RapidApp->active_request_context or return;
  
  # System 'administrator' role trumps everything:
  return if ($c->check_user_roles('administrator'));
  
  # Only admins can edit grids:
  $self->apply_extconfig( store_exclude_api => [qw(update destroy)] );
  
  
  my $User = Rapi::Blog::Util->get_User;
  
  my $source_name = $self->ResultSource->source_name;
  
  if($source_name eq 'Post') {
    if($User->author) {
      # authors can only post as themselves
      $self->apply_columns({ author => { allow_add => 0 } });
    
    }
    else {
      # Deny all changes to Post if the user is not an author
      $self->apply_extconfig( store_exclude_api => [qw(create update destroy)] );
    }
  }
  elsif($source_name eq 'Comment') {
    if($User->comment) {
      # commentors can only comment as themselves and only for the current time
      $self->apply_columns({ 
        user => { allow_add => 0 },
        ts   => { allow_add => 0 },
      });
    }
    else {
      # Deny all changes if the user is does not have 'comment'
      $self->apply_extconfig( store_exclude_api => [qw(create update destroy)] );
    }  
  }
  else {
    # deny all changes unless otherwise specified:
    $self->apply_extconfig( store_exclude_api => [qw(create update destroy)] );
  }

}



1;

