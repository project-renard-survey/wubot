package Wubot::Config;
use Moose;

use YAML;

has 'root'   => ( is      => 'ro',
                  isa     => 'Str',
                  required => 1,
              );

has 'config' => ( is      => 'ro',
                  isa     => 'HashRef',
                  default => sub { $_[0]->read_config() },
              );

sub read_config {
    my ( $self ) = @_;

    print "Reading configuration!\n";

    my $config = {};

    my $directory = $self->root;

    unless ( -d $directory ) {
        die "ERROR: config root directory does not exist: $directory\n";
    }

    my $mod_dir_h;
    opendir( $mod_dir_h, $directory ) or die "Can't opendir $directory: $!";

  MODULES:
    while ( defined( my $plugin = readdir( $mod_dir_h ) ) ) {
        next unless $plugin;
        next if $plugin =~ m|^\.|;

        my $plugin_dir = "$directory/$plugin";

        next unless -d $plugin_dir;

        print "Reading plugin directory: $plugin\n";

        my $instance_dir_h;

        opendir( $instance_dir_h, $plugin_dir ) or die "Can't opendir $plugin_dir: $!";

      INSTANCES:
        while ( defined( my $instance_entry = readdir( $instance_dir_h ) ) ) {
            next unless $instance_entry;

            next if -d "$plugin_dir/$instance_entry";
            next if $instance_entry =~ m|^\.|;

            print "\tReading instance config: $instance_entry\n";

            my $key = join( "-", $plugin, $instance_entry );
            $key =~ s|.yaml$||;

            my $instance_config = YAML::LoadFile( "$plugin_dir/$instance_entry" );
            $instance_config->{plugin} = "Wubot::Plugin::$plugin";

            $config->{$key} = { file   => $instance_entry,
                                dir    => $plugin,
                                config => $instance_config,
                                key    => $key,
                            };
        }

        closedir( $instance_dir_h );
    }

    closedir( $mod_dir_h );

    return $config;
}

sub get_plugins {
    my ( $self ) = @_;

    my @plugins;

    for my $plugin ( sort keys %{ $self->config } ) {

        push @plugins, $self->config->{$plugin}->{key};
    }

    return @plugins;
}

sub get_plugin_config {
    my ( $self, $plugin, $param ) = @_;

    unless ( $self->config->{$plugin} ) {
        die "ERROR: no config found for plugin $plugin";
    }

    unless ( $param ) {
        return $self->config->{$plugin}->{config};
    }

    unless ( $self->config->{$plugin}->{config}->{$param} ) {
        warn "ERROR: config param $param not found for plugin $plugin";
        return;
    }

    return $self->config->{$plugin}->{config}->{$param};
}

1;