[![Actions Status](https://github.com/raku-community-modules/XML-Canonical/actions/workflows/linux.yml/badge.svg)](https://github.com/raku-community-modules/XML-Canonical/actions) [![Actions Status](https://github.com/raku-community-modules/XML-Canonical/actions/workflows/macos.yml/badge.svg)](https://github.com/raku-community-modules/XML-Canonical/actions) [![Actions Status](https://github.com/raku-community-modules/XML-Canonical/actions/workflows/windows.yml/badge.svg)](https://github.com/raku-community-modules/XML-Canonical/actions)

NAME
====

XML::Canonical - Provide a canonical version of XML

SYNOPSIS
========

```raku
use XML::Canonical;

my $xml-string = canonical($xml);
my $xml-string = canonical($xml, :subset('/a/b/c'));
```

DESCRIPTION
===========

XML::Canonical is a module that exports a single subroutine `canonical` that transforms any given `XML` to a canonical version.

AUTHOR
======

Andrew Egeler

Source can be located at: https://github.com/raku-community-modules/XML-Canonical . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

