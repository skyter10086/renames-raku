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
    Int :c($concurrency) = 16,
) {
    say "🚀 File::Find 极速查找文件中...";

    # 🔥 关键：keep-going => True 跳过权限错误，继续运行
    my $files = find(
        dir => $dir,
        name => /<$pattern>/,
        type => 'file',
        recursive => $recursive,
        keep-going => True,  # ✅ 遇到权限错误不退出，继续扫描
    );

    # 并发重命名
    await $files.race(degree => $concurrency).map: -> $f {
        start {
            try {
                my IO::Path $real = $f;
                my $ext  = $real.extension;

                my $new-name;
                my $new-file;

                # 先生成，再判断是否存在（do while 等价）
                repeat {
                    $new-name = random-string(
                        chars => $char-len,
                        ranges => ['a'..'z', 'A'..'Z', '0'..'9']
                    );
                    $new-file = $real.parent.add($new-name);
                    $new-file .= extension($ext) if $ext;
                } while $new-file.e;

                say "✅ {$real.absolute} → {$new-file.absolute}";

                rename($real, $new-file) unless $dry;

                CATCH {
                    say "❌ 失败: {$real.absolute}";
                }
            }
        }
    }

    say "\n🎉 全部完成！";
}
