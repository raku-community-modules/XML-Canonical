use XML;

our proto canonical(|) is export {*}

my multi sub canonical(Str $xml, :$subset, :$exclusive, :@namespaces) {
    canonical(from-xml($xml).root, :$subset, :$exclusive, :@namespaces)
}

my multi sub canonical(XML::Document $xml, :$subset, :$exclusive, :@namespaces) {
    canonical($xml.root, :$subset, :$exclusive, :@namespaces)
}

my multi sub canonical(XML::Text $xml, *%) {
    my $text = $xml.text;

    # normalize line endings
    $text ~~ s:g/\n/\n/;

    # un-escape everything
    $text ~~ s:g/\&(\S+?)\;/{
        my $e = $0.Str.lc;

        if    $e eq 'amp'          { '&' }
        elsif $e eq 'apos'         { "'" }
        elsif $e eq 'lt'           { '<' }
        elsif $e eq 'gt'           { '>' }
        elsif $e eq 'quot'         { '"' }
        elsif $e ~~ /^<[0..9]>+$/  { chr($e) }
        elsif $e ~~ /^x<[0..9]>+$/ { chr(:16($e.substr(1))) }

        else { die "Unknown XML entity: "~$e }
    }/;

    escape-amp-lt-gt $text
}

my multi sub canonical(XML::CDATA $xml, *%) {
    escape-amp-lt-gt $xml.data
}

multi sub canonical(
  XML::Element $xml is copy,
           :$subset is copy,
           :$exclusive,
           :$namespaces,
           :%exc-rendered-ns is copy
) {
    my @namespaces = @$namespaces;
    %exc-rendered-ns{'#default'} = '' unless %exc-rendered-ns;

    my %extra-attribs;
    if $subset {
        my @parts = $subset.split(/\//).grep({$_});
        die "Invalid subset" if @parts[0] ne $xml.name;
        @parts.shift;
        while @parts {
            for $xml.attribs.kv -> $k, $v {
                if $k ~~ /^xmlns(.*)?/ {
                    my $part = $0.Str;
                    $part ~~ s/\:// if $part;
                    if !$exclusive || @namespaces.grep({ $part ?? $_ eq $part !! $_ eq '#default' }) {
                        %extra-attribs{$k} = $v;
                        %exc-rendered-ns{$k} = $v;
                    }
                }
            }
            my $tmp = $xml.elements(:TAG(@parts[0]), :SINGLE);
            die "Invalid subset" unless $tmp;
            $xml := $tmp;
            @parts.shift;
        }
    }

    my $element = '<' ~ $xml.name;
    my @keys = $xml.attribs.keys;

    @keys = @keys.grep: { needed-attribute $xml, $_ }

    if $exclusive {
        # special namespace rules, so strip out all xmlns attributes
        # (inclusivenamespaces rule handled with extra-attribs below)
        @keys .= grep({ !( $_ ~~ /^xmlns/ ) });

        my %used_ns;
        for @keys {
            my @s = .split(/\:/);
            if @s.elems > 1 {
                %used_ns{@s[0]}++;
            }
        }
        my @s = $xml.name.split(/\:/);
        if @s.elems > 1 {
            %used_ns{@s[0]}++;
        }
        else {
            %used_ns{'#default'}++;
        }

        for %used_ns.keys {
            if !(%exc-rendered-ns{$_}:exists)
              || %exc-rendered-ns{$_} ne ($_ eq '#default'
                   ?? $xml.nsURI('')
                   !! $xml.nsURI($_)
            ) {
                if $_ eq '#default' {
                    %extra-attribs{'xmlns'} = $xml.nsURI('');
                    %exc-rendered-ns{'#default'} = $xml.nsURI('');
                }
                else {
                    %extra-attribs{'xmlns:' ~ $_} = $xml.nsURI($_);
                    %exc-rendered-ns{$_} = $xml.nsURI($_);
                }
            }
        }
    }

    @keys.append(%extra-attribs.keys);

    @keys = @keys.sort: -> $a, $b { compare-attributes $xml, $a, $b }

    for @keys -> $k {
        my $v = %extra-attribs{$k};
        $v //= $xml.attribs{$k};

        # escape " < > &
        $v = $v
          .subst('&', '&amp;')
          .subst('"', '&quot;')
          .subst('<', '&lt;')
          .subst('>', '&gt;');

        $element ~= " $k=\"$v\"";
    }
    $element ~= '>';

    for $xml.nodes {
        $element ~= canonical($_, :$exclusive, :@namespaces, :%exc-rendered-ns);
    }

    $element ~= '</' ~ $xml.name ~ '>';

    $element
}

my sub needed-attribute($xml, $key) {
    return True unless $key ~~ /^xmlns/;

    if $xml.parent ~~ XML::Document {
        $xml.attribs{$key}.Bool
    }
    else {
        my $value := $xml.attribs{$key};
        my @keyparts = $key.split(/\:/);
        @keyparts[1] ||= '';

        $xml.parent.nsURI(@keyparts[1]) ne $value
    }
}

my sub compare-attributes($xml, $a, $b) {
    # namespaces go first
    if is-xmlns($a) && !is-xmlns($b) {
        Less
    }
    elsif is-xmlns($b) && !is-xmlns($a) {
        More
    }
    # namespaces ordered simply
    elsif is-xmlns($a) && is-xmlns($b) {
        $a cmp $b
    }
    # attributes ordered by namespace, then name
    # if no namespace, treat the namespace as "" (empty string)
    else {
        my @aparts = $a.split(/\:/);
        if @aparts[1] {
            @aparts[0] = $xml.nsURI(@aparts[0]);
        }
        else {
            @aparts[1] = @aparts[0];
            @aparts[0] = '';
        }

        my @bparts = $b.split(/\:/);
        if @bparts[1] {
            @bparts[0] = $xml.nsURI(@bparts[0]);
        }
        else {
            @bparts[1] = @bparts[0];
            @bparts[0] = '';
        }

        @aparts[0] cmp @bparts[0] || @aparts[1] cmp @bparts[1]
    }
}

sub is-xmlns($a) {
    $a eq 'xmlns' || $a.starts-with('xmlns:')
}

# escape < > &
my sub escape-amp-lt-gt(Str:D $text) {
    $text
      .subst('&','&amp;')
      .subst('<','&lt;')
      .subst('>','&gt;')
}

=begin pod

=head1 NAME

XML::Canonical - Provide a canonical version of XML

=head1 SYNOPSIS

=begin code :lang<raku>

use XML::Canonical;

my $xml-string = canonical($xml);
my $xml-string = canonical($xml, :subset('/a/b/c'));

=end code

=head1 DESCRIPTION

ZXML::Canonical is a module that exports a single subroutine C<canonical>
that transforms any given C<XML> to a canonical version.

=head1 AUTHOR

Andrew Egeler

Source can be located at: https://github.com/raku-community-modules/XML-Canonical .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
