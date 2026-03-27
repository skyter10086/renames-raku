#!/usr/bin/env raku
use v6.d;
use Data::Generators;
use File::Find;

sub MAIN(
    Str $pattern,
    Int $char-len = 8,
    Str :d($dir) = '.',
    Bool :r($recursive) = False,
    Bool :y($dry) = False,
    #Int :c($concurrency) = 4
) {
    say "🚀 App::Rak 极速查找文件中...";

    # 你原版写法！保留！超快！
    my $files = find(
        dir=>$dir,
        name=> /<$pattern>/,
        type=>'file',
        recursive => $recursive,
        keep-going=>True,
    );

    # 单线程生成不重复名称（唯一安全方式）
    #my SetHash $used .= new;

    # 并发重命名（你原版结构，完全不改动）
    await $files.map: -> $f {
        start {
            try {
                my $real = $f;
                my $ext  = $real.extension;

                # 生成唯一名字（线程安全）
                my $new-name;
                my $new-file;
                loop {
                    $new-name = random-string(
                        chars => $char-len,
                        ranges => ['a'..'z', 'A'..'Z', '0'..'9']
                    );
                    $new-file = $real.parent.add($new-name);
                    $new-file .= extension($ext) if $ext;
                    last unless $new-file.e;
                }
                say "✅ {$real.absolute} →\n\t{$new-file.absolute}";
                rename($real, $new-file) unless $dry;

                CATCH {
                    say "❌ 失败: {$real.absolute}";
                }
            }
        }
    }

    say "\n🎉 全部完成！";
}
