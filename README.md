[![Build Status](https://travis-ci.org/dayflower/p5-Image-JpegQuality.png?branch=master)](https://travis-ci.org/dayflower/p5-Image-JpegQuality)
# NAME

Image::JpegQuality - Estimate quality of JPEG images.

# SYNOPSIS

    use Image::JpegQuality;

    say jpeg_quality('filename.jpg');
    say jpeg_quality(HANDLE);
    say jpeg_quality(\$image_data);

# DESCRIPTION

Image::JpegQuality determines quality of JPEG file.
It's approximate value because the quality is not stored in the file explicitly.
This module calculates quality from luminance quantization table stored in the file.

# METHODS

- jpeg\_quality($stuff)

    Returns quality (1-100) of JPEG file.

        scalar:     filename
        scalarref:  JPEG data itself
        file-glob:  file handle

# LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ITO Nobuaki <daydream.trippers@gmail.com>
