#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 102;

use Mojo::ByteStream 'b';

# "We should be safe up here. I'm pretty sure fires can't climb trees."
use_ok 'Mojo::JSON';

my $json = Mojo::JSON->new;

# Decode array
my $array = $json->decode('[]');
is_deeply $array, [], 'decode []';
$array = $json->decode('[ [ ]]');
is_deeply $array, [[]], 'decode [ [ ]]';

# Decode number
$array = $json->decode('[0]');
is_deeply $array, [0], 'decode [0]';
$array = $json->decode('[1]');
is_deeply $array, [1], 'decode [1]';
$array = $json->decode('[ "-122.026020" ]');
is_deeply $array, ['-122.026020'], 'decode [ -122.026020 ]';
$array = $json->decode('[ -122.026020 ]');
is_deeply $array, ['-122.02602'], 'decode [ -122.026020 ]';
$array = $json->decode('[0.0]');
isa_ok $array, 'ARRAY', 'decode [0.0]';
cmp_ok $array->[0], '==', 0, 'value is 0';
$array = $json->decode('[0e0]');
isa_ok $array, 'ARRAY', 'decode [0e0]';
cmp_ok $array->[0], '==', 0, 'value is 0';
$array = $json->decode('[1,-2]');
is_deeply $array, [1, -2], 'decode [1,-2]';
$array = $json->decode('["10e12" , [2 ]]');
is_deeply $array, ['10e12', [2]], 'decode ["10e12" , [2 ]]';
$array = $json->decode('[10e12 , [2 ]]');
is_deeply $array, [10000000000000, [2]], 'decode [10e12 , [2 ]]';
$array = $json->decode('[37.7668 , [ 20 ]] ');
is_deeply $array, [37.7668, [20]], 'decode [37.7668 , [ 20 ]] ';
$array = $json->decode('[1e3]');
isa_ok $array, 'ARRAY', 'decode [1e3]';
cmp_ok $array->[0], '==', 1e3, 'value is 1e3';

# Decode name
$array = $json->decode('[true]');
is_deeply $array, [$json->true], 'decode [true]';
$array = $json->decode('[null]');
is_deeply $array, [undef], 'decode [null]';
$array = $json->decode('[true, false]');
is_deeply $array, [$json->true, $json->false], 'decode [true, false]';

# Decode string
$array = $json->decode('[" "]');
is_deeply $array, [' '], 'decode [" "]';
$array = $json->decode('["hello world!"]');
is_deeply $array, ['hello world!'], 'decode ["hello world!"]';
$array = $json->decode('["hello\nworld!"]');
is_deeply $array, ["hello\nworld!"], 'decode ["hello\nworld!"]';
$array = $json->decode('["hello\t\"world!"]');
is_deeply $array, ["hello\t\"world!"], 'decode ["hello\t\"world!"]';
$array = $json->decode('["hello\u0152world\u0152!"]');
is_deeply $array, ["hello\x{0152}world\x{0152}!"],
  'decode ["hello\u0152world\u0152!"]';
$array = $json->decode('["0."]');
is_deeply $array, ['0.'], 'decode ["0."]';
$array = $json->decode('[" 0"]');
is_deeply $array, [' 0'], 'decode [" 0"]';
$array = $json->decode('["1"]');
is_deeply $array, ['1'], 'decode ["1"]';

# Decode object
my $hash = $json->decode('{}');
is_deeply $hash, {}, 'decode {}';
$hash = $json->decode('{"foo": "bar"}');
is_deeply $hash, {foo => 'bar'}, 'decode {"foo": "bar"}';
$hash = $json->decode('{"foo": [23, "bar"]}');
is_deeply $hash, {foo => [qw/23 bar/]}, 'decode {"foo": [23, "bar"]}';

# Decode full spec example
$hash = $json->decode(<<EOF);
{
   "Image": {
       "Width":  800,
       "Height": 600,
       "Title":  "View from 15th Floor",
       "Thumbnail": {
           "Url":    "http://www.example.com/image/481989943",
           "Height": 125,
           "Width":  "100"
       },
       "IDs": [116, 943, 234, 38793]
    }
}
EOF
is $hash->{Image}->{Width},  800,                    'right value';
is $hash->{Image}->{Height}, 600,                    'right value';
is $hash->{Image}->{Title},  'View from 15th Floor', 'right value';
is $hash->{Image}->{Thumbnail}->{Url},
  'http://www.example.com/image/481989943', 'right value';
is $hash->{Image}->{Thumbnail}->{Height}, 125, 'right value';
is $hash->{Image}->{Thumbnail}->{Width},  100, 'right value';
is $hash->{Image}->{IDs}->[0], 116,   'right value';
is $hash->{Image}->{IDs}->[1], 943,   'right value';
is $hash->{Image}->{IDs}->[2], 234,   'right value';
is $hash->{Image}->{IDs}->[3], 38793, 'right value';

# Encode array
my $string = $json->encode([]);
is $string, '[]', 'encode []';
$string = $json->encode([[]]);
is $string, '[[]]', 'encode [[]]';
$string = $json->encode([[], []]);
is $string, '[[],[]]', 'encode [[], []]';
$string = $json->encode([[], [[]], []]);
is $string, '[[],[[]],[]]', 'encode [[], [[]], []]';

# Encode string
$string = $json->encode(['foo']);
is $string, '["foo"]', 'encode [\'foo\']';
$string = $json->encode(["hello\nworld!"]);
is $string, '["hello\nworld!"]', 'encode ["hello\nworld!"]';
$string = $json->encode(["hello\t\"world!"]);
is $string, '["hello\t\"world!"]', 'encode ["hello\t\"world!"]';
$string = $json->encode(["hello\x{0003}\x{0152}world\x{0152}!"]);
is b($string)->decode('UTF-8'), "[\"hello\\u0003\x{0152}world\x{0152}!\"]",
  'encode ["hello\x{0003}\x{0152}world\x{0152}!"]';
$string = $json->encode(["123abc"]);
is $string, '["123abc"]', 'encode ["123abc"]';

# Encode object
$string = $json->encode({});
is $string, '{}', 'encode {}';
$string = $json->encode({foo => {}});
is $string, '{"foo":{}}', 'encode {foo => {}}';
$string = $json->encode({foo => 'bar'});
is $string, '{"foo":"bar"}', 'encode {foo => \'bar\'}';
$string = $json->encode({foo => []});
is $string, '{"foo":[]}', 'encode {foo => []}';
$string = $json->encode({foo => ['bar']});
is $string, '{"foo":["bar"]}', 'encode {foo => [\'bar\']}';

# Encode name
$string = $json->encode([$json->true]);
is $string, '[true]', 'encode [$json->true]';
$string = $json->encode([undef]);
is $string, '[null]', 'encode [undef]';
$string = $json->encode([$json->true, $json->false]);
is $string, '[true,false]', 'encode [$json->true, $json->false]';

# Encode number
$string = $json->encode([1]);
is $string, '[1]', 'encode [1]';
$string = $json->encode(["1"]);
is $string, '["1"]', 'encode ["1"]';
$string = $json->encode(['-122.026020']);
is $string, '["-122.026020"]', 'encode [\'-122.026020\']';
$string = $json->encode([-122.026020]);
is $string, '[-122.02602]', 'encode [-122.026020]';
$string = $json->encode([1, -2]);
is $string, '[1,-2]', 'encode [1, -2]';
$string = $json->encode(['10e12', [2]]);
is $string, '["10e12",[2]]', 'encode [\'10e12\', [2]]';
$string = $json->encode([10e12, [2]]);
is $string, '[10000000000000,[2]]', 'encode [10e12, [2]]';
$string = $json->encode([37.7668, [20]]);
is $string, '[37.7668,[20]]', 'encode [37.7668, [20]]';

# Faihu roundtrip
$string = $json->encode(["\x{10346}"]);
is b($string)->decode('UTF-8'), "[\"\x{10346}\"]", 'encode ["\x{10346}"]';
$array = $json->decode($string);
is_deeply $array, ["\x{10346}"], 'successful roundtrip';

# Decode UTF-16LE
$array = $json->decode(b("\x{feff}[true]")->encode('UTF-16LE'));
is_deeply $array, [$json->true], 'decode \x{feff}[true]';

# Decode UTF-16LE with faihu surrogate pair
$array = $json->decode(b("\x{feff}[\"\\ud800\\udf46\"]")->encode('UTF-16LE'));
is_deeply $array, ["\x{10346}"], 'decode \x{feff}[\"\\ud800\\udf46\"]';

# Decode UTF-16LE with faihu surrogate pair and BOM value
$array = $json->decode(
    b("\x{feff}[\"\\ud800\\udf46\x{feff}\"]")->encode('UTF-16LE'));
is_deeply $array, ["\x{10346}\x{feff}"],
  'decode \x{feff}[\"\\ud800\\udf46\x{feff}\"]';

# Decode UTF-16LE with missing high surrogate
$array = $json->decode(b("\x{feff}[\"\\ud800\"]")->encode('UTF-16LE'));
is_deeply $array, ['\ud800'], 'decode \x{feff}[\"\\ud800\"]';

# Decode UTF-16LE with missing low surrogate
$array = $json->decode(b("\x{feff}[\"\\udf46\"]")->encode('UTF-16LE'));
is_deeply $array, ['\udf46'], 'decode \x{feff}[\"\\udf46\"]';

# Decode UTF-16BE with faihu surrogate pair
$array = $json->decode(b("\x{feff}[\"\\ud800\\udf46\"]")->encode('UTF-16BE'));
is_deeply $array, ["\x{10346}"], 'decode \x{feff}[\"\\ud800\\udf46\"]';

# Decode UTF-32LE
$array = $json->decode(b("\x{feff}[true]")->encode('UTF-32LE'));
is_deeply $array, [$json->true], 'decode \x{feff}[true]';

# Decode UTF-32BE
$array = $json->decode(b("\x{feff}[true]")->encode('UTF-32BE'));
is_deeply $array, [$json->true], 'decode \x{feff}[true]';

# Decode UTF-16LE without BOM
$array =
  $json->decode(b("[\"\\ud800\\udf46\"]")->encode('UTF-16LE')->to_string);
is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';

# Decode UTF-16BE without BOM
$array =
  $json->decode(b("[\"\\ud800\\udf46\"]")->encode('UTF-16BE')->to_string);
is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';

# Decode UTF-32LE without BOM
$array =
  $json->decode(b("[\"\\ud800\\udf46\"]")->encode('UTF-32LE')->to_string);
is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';

# Decode UTF-32BE without BOM
$array =
  $json->decode(b("[\"\\ud800\\udf46\"]")->encode('UTF-32BE')->to_string);
is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';

# Complicated roudtrips
$string = '[null,false,true,"",0,1]';
$array  = $json->decode($string);
isa_ok $array, 'ARRAY', 'decode [null,false,true,"",0,1]';
is $json->encode($array), $string, 'reencode';
$array = [undef, 0, 1, '', $json->true, $json->false];
$string = $json->encode($array);
ok $string, 'defined value';
is_deeply $json->decode($string), $array, 'successful roundtrip';

# Real world roundtrip
$string = $json->encode({foo => 'c:\progra~1\mozill~1\firefox.exe'});
is $string, '{"foo":"c:\\\\progra~1\\\\mozill~1\\\\firefox.exe"}',
  'encode {foo => \'c:\progra~1\mozill~1\firefox.exe\'}';
$hash = $json->decode($string);
is_deeply $hash, {foo => 'c:\progra~1\mozill~1\firefox.exe'},
  'successful roundtrip';

# Errors
is $json->decode('[[]'), undef, 'missing right square bracket';
is $json->error, 'Missing right square bracket near end of file.',
  'right error';
is $json->decode('{{}'), undef, 'missing right curly bracket';
is $json->error, 'Missing right curly bracket near end of file.',
  'right error';
is $json->decode('[[]...'), undef, 'syntax error';
is $json->error, 'Syntax error near "...".', 'right error';
is $json->decode('{{}...'), undef, 'syntax error';
is $json->error, 'Syntax error near "...".', 'right error';
is $json->decode('[nan]'), undef, 'syntax error';
is $json->error, 'Syntax error near "nan]".', 'right error';
is $json->decode('["foo]'), undef, 'syntax error';
is $json->error, 'Syntax error near ""foo]".', 'right error';
is $json->decode('false'), undef, 'no object or array';
is $json->error, 'JSON text has to be a serialized object or array.',
  'right error';
is $json->decode(''), undef, 'no object or array';
is $json->error, 'JSON text has to be a serialized object or array.',
  'right error';
