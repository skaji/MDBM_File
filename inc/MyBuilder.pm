package MyBuilder;
use strict;
use warnings;
use Config;
use File::Spec;

use base 'Module::Build';

sub new {
    my ($class, @argv) = @_;
    !system qw(git submodule update --init --force) or die;
    my @linker = qw(-lm -lpthread -lcrypto -ldl -lstdc++);
    if ($^O eq 'darwin') {
        unshift @linker, "-L/usr/local/opt/openssl/lib" if -d "/usr/local/opt/openssl/lib";
    } else {
        push @linker, "-lrt";
    }
    $class->SUPER::new(
        include_dirs => ["mdbm/include"],
        extra_linker_flags => \@linker,
        @argv,
    );
}

sub ACTION_code {
    my ($self, @argv) = @_;

    !system $Config{make}, "-C", "mdbm/src/lib" or die;
    push @{$self->{properties}{objects} ||= []}, glob "mdbm/src/lib/object/*.o";
    {
        local $self->{properties}{extra_compiler_flags} = ["-xc++"];
        push @{$self->{properties}{objects}}, $self->compile_c("lib/shakedata.cc");
    }

    $self->SUPER::ACTION_code(@argv);

    my $file = File::Spec->catfile($self->blib, "lib", "MDBM_File.pm");
    my $dir = File::Spec->catdir($self->blib, "lib", "auto");
    mkdir $dir;
    $self->autosplit_file($file, $self->blib);
}

1;
