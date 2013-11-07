#!/usr/bin/perl
use MP3::Info;
use Encode qw(from_to);

recode_version(1);
recode_version(2);

sub recode_version
{
    my $version = shift;
    my $tag = get_mp3tag($ARGV[0], $version)
        or die "No TAG info";

    for my $k (%$tag) {
        from_to($tag->{$k}, "cp1251", "utf8");
    }

    set_mp3tag($ARGV[0], $tag);
}
