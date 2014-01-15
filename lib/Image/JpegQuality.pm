package Image::JpegQuality;
use 5.008005;
use strict;
use warnings;
use Exporter 'import';
use Carp;
use IO::Handle;
use IO::File;

our $VERSION = "0.01";

our @EXPORT = qw( jpeg_quality );

use constant {
    SECTION_MARKER => "\xFF",
    SOI => "\xFF\xD8",
    EOI => "\xFF\xD8",
    SOS => "\xFF\xDA",
    DQT => "\xFF\xDB",

    ERR_NOT_JPEG  => "Not a JPEG file",
    ERR_FILE_READ => "File read error",
    ERR_FAILED    => "Could not determine quality",
};

sub jpeg_quality {
    my ($file) = @_;

    my ($fh, $r);
    if (! ref $file) {
        $fh = IO::File->new;
        $fh->open($file, 'r')  or croak ERR_FILE_READ . qq{: $!};
        $fh->binmode();
        $r = _jpeg_quality_for_fh($fh);
        $fh->close();
        return $r;
    } elsif (ref $file eq 'GLOB') {
        $fh = $file;
        $fh->binmode();
        $r = _jpeg_quality_for_fh($fh);
        return $r;
    } elsif (ref $file eq 'SCALAR') {
        open $fh, '<', $file  or croak ERR_FILE_READ . qq{: $!};
        $fh->binmode();
        $r = _jpeg_quality_for_fh($fh);
        $fh->close();
        return $r;
    } elsif (eval { $file->can('read') }) {
        $fh = $file;
        $fh->binmode();
        $r = _jpeg_quality_for_fh($fh);
        return $r;
    } else {
        croak "Unsupported file: $file";
    }
}

# TODO: lossless support

sub _jpeg_quality_for_fh {
    my ($fh) = @_;
    my ($buf);

    $fh->read($buf, 2)  or croak ERR_FILE_READ . qq{: $!};
    croak ERR_NOT_JPEG unless $buf eq SOI;

    while (1) {
        $fh->read($buf, 2)  or croak ERR_FILE_READ . qq{: $!};

        if ($buf eq EOI) {
            croak ERR_FAILED;
        }
        if ($buf eq SOS) {
            croak ERR_FAILED;
        }

        my $marker = substr $buf, 0, 1;
        croak ERR_NOT_JPEG unless $marker eq SECTION_MARKER;

        if ($buf ne DQT) {
            # skip to next segment
            $fh->read($buf, 2)  or croak ERR_FILE_READ . qq{: $!};
            my $len = unpack 'n', $buf;
            $fh->seek($len - 2, 1)  or croak ERR_FILE_READ . qq{: $!};
            next;
        }

        # read DQT length
        $fh->read($buf, 2)  or croak ERR_FILE_READ . qq{: $!};
        my $len = unpack 'n', $buf;
        $len -= 2;
        croak ERR_FAILED unless $len >= 64+1;

        # read DQT
        $fh->read($buf, $len)  or croak ERR_FILE_READ . qq{: $!};

        my $dqt8bit = ((ord substr($buf, 0, 1) & 0xF0) == 0);

        return _judge_quality($buf, $dqt8bit);
    }

    # NEVER REACH HERE
}

# Precalculated sums of luminance quantization table for each qualities.
# Base table is from Table K.1 in JPEG Standard Annex K

my @sums_dqt = (
    16320, 16316, 15954, 15287, 14674, 14094, 13645, 13247, 12886, 12586,
    12275, 11900, 11506, 11125, 10760, 10413, 10073, 9750, 9422, 9089,
    8739, 8405, 8067, 7745, 7440, 7156, 6893, 6647, 6424, 6212,
    6013, 5825, 5648, 5486, 5329, 5184, 5044, 4916, 4793, 4668,
    4566, 4460, 4354, 4252, 4161, 4072, 3993, 3906, 3819, 3752,
    3685, 3605, 3531, 3460, 3383, 3311, 3234, 3160, 3085, 3016,
    2938, 2868, 2791, 2721, 2643, 2573, 2501, 2426, 2354, 2275,
    2200, 2132, 2060, 1979, 1894, 1837, 1756, 1684, 1616, 1541,
    1462, 1390, 1315, 1243, 1169, 1095, 1025, 948, 878, 800,
    731, 656, 582, 505, 429, 356, 285, 211, 131, 64
);

sub _judge_quality {
    my ($buf, $is_8bit) = @_;

    my $sum = 0;
    if ($is_8bit) {
        $sum += $_ for map { unpack('C', substr($buf, 1+1*$_, 1)) } (1..64);
    } else {
        $sum += $_ for map { unpack('n', substr($buf, 1+2*$_, 2)) } (1..64);
        $sum /= 256;
    }

    for my $i (0 .. 99) {
        if ($sum < $sums_dqt[99 - $i]) {
            return 100 - $i;
        }
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Image::JpegQuality - Estimate quality of JPEG images.

=head1 SYNOPSIS

    use Image::JpegQuality;

    say jpeg_quality('filename.jpg');
    say jpeg_quality(HANDLE);
    say jpeg_quality(\$image_data);

=head1 DESCRIPTION

Image::JpegQuality determines quality of JPEG file.
It's approximate value because the quality is not stored in the file explicitly.
This module calculates quality from luminance quantization table stored in the file.

=head1 METHODS

=over 4

=item jpeg_quality($stuff)

Returns quality (1-100) of JPEG file.

    scalar:     filename
    scalarref:  JPEG data itself
    file-glob:  file handle

=back

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>daydream.trippers@gmail.comE<gt>

=cut

