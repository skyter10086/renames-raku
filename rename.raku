#!/usr/bin/env raku
use v6.d;
use Data::Generators;
use File::Find;

sub MAIN(Str $files-rx,
        Int $char-len=8,
         Str :d($dir)='.',
        Bool :r($recursive)=False,
        Bool :y($dry)=False ) {
    for find(dir=>$dir, name=> {/<$files-rx>/}, recursive=>$recursive) -> $file {
        my $new-name = random-string(chars=>$char-len,ranges=>['a'..'z','A'..'Z','0'..'9']);
        #say $new-name;
        my $new-file;
        if $file.extension {
            $new-file = $file.absolute.IO.resolve.parent.add($new-name).extension: $file.extension;
        } else {
            $new-file = $file.absolute.IO.resolve.parent.add($new-name);
        }

        say "$file renames to: ";
        say  "\t {$new-file.absolute}";
        rename($file,$new-file) if $dry == False;
    }
}
