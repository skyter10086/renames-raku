#!/usr/bin/env raku
use v6.d;
use Data::Generators;
use File::Find;

sub MAIN(
    Str $files-rx,
    Int $char-len = 8,
    Str :d($dir) = '.',
    Bool :r($recursive) = False,
    Bool :y($dry) = False,
    Int :$concurrency = 16  # 并发数，SSD 可调 32，机械盘 8
) {
    # 🔥 内置 Supply，无需任何 use
# 🔥 核心：Seq 直接转 Supply（一行搞定！）
    my $file-supply = find(
        dir => $dir,
        name => { /<$files-rx>/ },
        recursive => $recursive
    ).Supply;

    # 异步并发处理（正确写法：map -> start -> flat）
    $file-supply
        .map(-> $file { start process-file($file) })
        .flat
        .wait;

    say "\n✅ 所有文件重命名完成！";

    # 单独抽取处理函数，代码更干净
    sub process-file(IO::Path $file) {
        my $real = $file.resolve;
        my $new-name = random-string(
            chars => $char-len,
            ranges => ['a'..'z', 'A'..'Z', '0'..'9']
        );

        my $ext = $real.extension;
        my $new-file = $real.parent.add($new-name);
        $new-file .= extension($ext) if $ext;

        say "$real => \n\t{$new-file.absolute}";
        rename($real, $new-file) if !$dry;
    }
}
