package Rapi::Blog::Util::Rabl::Create;
use strict;
use warnings;

# ABSTRACT: Rabl module for creating new Rapi::Blog sites

use Moo;
extends 'Rapi::Blog::Util::Rabl';

use RapidApp::Util ':all';
use Rapi::Blog;

use Path::Class qw(file dir);
use Scalar::Util 'blessed';

sub call {
  my $class = shift;
  my $path = shift || $ARGV[0];
  my $scaffold_name = shift || $ARGV[1] || 'bootstrap-blog';
  
  $class->usage unless ($path);
  
  my $Dir = dir($path);
  if(-d $Dir) {
    my $count = $Dir->children;
    die "Target directory '$Dir' already exists and is not empty - aborting.\n" if ($count > 0);
  }
  else {
    my $parent = $Dir->parent;
    die "Parent dir '$parent' not found; automatic creation of parent dirs is not supported.\n"
      unless (-d $parent);
    print "==> creating '$Dir'";
    $Dir->mkpath;
    print "\n";
  }
  
  my $share_dir = Rapi::Blog->_get_share_dir or die "Unable to identify ShareDir for Rapi::Blog.\n";
  
  my $Scafs = dir($share_dir)->subdir('scaffolds')->resolve;
  
  my $ScafDir = $Scafs->subdir($scaffold_name);
  die "Scaffold '$scaffold_name' not found in ShareDir\n" unless (-d $ScafDir);
  
  my $TargScaf = $Dir->subdir('scaffold');
  
  $class->_recursive_copy($ScafDir,$TargScaf);
  
  
}



sub _recursive_copy {
  my $class = shift;
  my ($src, $dst, $depth) = @_;
  $depth ||= 0;
  
  die "bad src '$src' - not a Path::Class::Dir" unless (
    blessed $src && $src->isa('Path::Class::Dir')
  );
  
  die "bad dst '$dst' - not a Path::Class::Dir" unless (
    blessed $dst && $dst->isa('Path::Class::Dir')
  );
  
  unless (-d $dst) {
    die "Error -- refuse to sync to a dir with non-existing parent dir" unless (-d $dst->parent);
    print '  ' x $depth;
    $dst->mkpath(1);
  }
  
  my (@files,@dirs);
  
  for my $itm ($src->children) {
    die "unexpected child item '$itm'" unless (blessed $itm);
    if($itm->isa('Path::Class::Dir')) {
      push @dirs,$itm;
    }
    elsif($itm->isa('Path::Class::File')) {
      push @files, $itm
    }
    else {
      die "unexpected child item '$itm'"
    }
  }
  
  # files first"
  for my $itm (@files) {
    my $tfile = $dst->file($itm->basename);
    die "target file '$tfile' already exists!" if (-e $tfile);
    print '  ' x $depth;
    print '  - ' . $itm->relative($src);
    $tfile->spew( scalar $itm->slurp );
    print "\n";
  }
  
  for my $itm (@dirs) {
    $class->_recursive_copy($itm, $dst->subdir( $itm->basename ),$depth + 1);
  }
}



1;


__END__

=head1 NAME

Rapi::Blog::Util::Rabl::Create - Create/bootstrap new Rapi::Blog site

=head1 SYNOPSIS

 rabl.pl create [NEW_SITE_PATH]
 
 Examples:
   rabl.pl create path/to/my-cool-site

=head1 DESCRIPTION

This module provides automatic creation/bootstrap of a new Rapi::Blog site within
the specified directory, which should not exist, or be empty.

=head1 SEE ALSO

=over

=item * 

L<Rapi::Blog>

=item * 

L<rabl.pl>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
