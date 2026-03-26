#!/usr/bin/env raku
use v6.d;
use Data::Generators;
use paths;

sub MAIN(
    Str $pattern,
    Int $char-len = 8,
    Str :d($dir) = '.',        # 已修复语法
    Bool :r($recursive) = True,
    Bool :y($dry) = False,
    Int :$concurrency = 4
) {
    say "🚀 App::Rak 极速查找文件中...";

    # ===========================
    # 官方正确：find 模式（只查文件名）
    # ===========================
    my $files = paths(
        $dir,
        file => /<$pattern>/,
        recurse => $recursive,
    );

 #   say "✅ 找到 {+@files} 个文件";

    # ===========================
    # 异步并发重命名
    # ===========================
    await $files.map: -> $f {
        start {
            try {
                my $real = $f.IO.resolve;
                my $ext  = $real.extension;

                my $new-name = random-string(
                    chars => $char-len,
                    ranges => ['a'..'z', 'A'..'Z', '0'..'9']
                );

                my $new-file = $real.parent.add($new-name);
                $new-file .= extension($ext) if $ext;

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

