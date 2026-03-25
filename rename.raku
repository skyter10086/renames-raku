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
    Int :$concurrency = 32  # 并发数，SSD 可调 32，机械盘 8
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
        .flat(concurrency => $concurrency) # 👈 控制并发
        .wait;

    say "\n✅ 所有文件重命名完成！";

    # 带异常捕获的处理函数
    sub process-file(IO::Path $real) {
        try {
            # 你确认可用的正确写法
            my $ext = $real.extension;

            my $new-name = random-string(
                chars => $char-len,
                ranges => ['a'..'z','A'..'Z','0'..'9']
            );

            # 构建新文件名（保持原目录）
            my $new-file = $real.parent.add($new-name);
            $new-file .= extension($ext) if $ext;

            say "✅ $real →\n\t$new-file";

            # 执行重命名
            rename($real, $new-file) if !$dry;

            CATCH {
                say "❌ 处理失败：$real → {.message}";
            }
        }
    }
}
