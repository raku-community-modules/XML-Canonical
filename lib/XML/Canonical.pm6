use XML;

module XML::Canonical;

our proto canonical(|) is export { * };

multi sub canonical(Str $xml) {
    return canonical(from-xml($xml).root);
}

multi sub canonical(XML::Document $xml) {
    return canonical($xml.root);
}

multi sub canonical(XML::Node $xml) {
    if ($xml ~~ XML::Text) {
        # TODO: escaping, etc
        my $text = $xml.text;
        $text ~~ s:g/\n/\n/; # normalize line endings
        return $text;
    }

    my $element = '<' ~ $xml.name;
    my @keys = $xml.attribs.keys;

    @keys .= sort(-> $a, $b {
        # namespaces go first
        if _is_xmlns($a) && !_is_xmlns($b) {
            Less;
        }
        elsif _is_xmlns($b) && !_is_xmlns($a) {
            More;
        }
        # namespaces ordered simply
        elsif _is_xmlns($a) && _is_xmlns($b) {
            $a cmp $b;
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

            my $p0 = @aparts[0] cmp @bparts[0];
            if $p0 ne Same {
                $p0;
            }
            else {
                @aparts[1] cmp @bparts[1];
            }
        }
    });

    for @keys -> $k {
        my $v = $xml.attribs{$k};
        $element ~= " $k=\"$v\"";
    }
    $element ~= '>';

    for $xml.nodes {
        $element ~= canonical($_);
    }

    $element ~= '</' ~ $xml.name ~ '>';

    return $element;
}

sub _is_xmlns($a) {
    return True if ($a eq 'xmlns' || $a ~~ /^xmlns\:/);
    False;
}
