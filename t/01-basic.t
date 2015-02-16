use v6;
use Test;

plan 5;

use XML::Canonical;

is canonical("<a/>"), "<a></a>", 'Empty node';
is canonical("<a  ><b \n  ><c/></b></a>"), '<a><b><c></c></b></a>', 'nested empty';
is canonical("<a \n  second='b'\nfirst='a'/>"), '<a first="a" second="b"></a>', 'attributes, whitespace, ordering';

is canonical("<a>\r\n Foo Bar\nBaz<b>xyzzy\n woo</b> zz\r\nxx</a>"),
             "<a>\n Foo Bar\nBaz<b>xyzzy\n woo</b> zz\nxx</a>",
             'convert newlines, preserve whitespace in text nodes';

is canonical("<a foo='bar' baz='boo' xmlns='nsa' xmlns:a='nsb' />"),
             "<a xmlns=\"nsa\" xmlns:a=\"nsb\" baz=\"boo\" foo=\"bar\"></a>",
             'namespace declarations before normal attributes';
