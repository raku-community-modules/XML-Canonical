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
        if _is_xmlns($a) && !_is_xmlns($b) {
            Less;
        }
        elsif _is_xmlns($b) && !_is_xmlns($a) {
            More;
        }
        else {
            $a cmp $b;
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
