#!/usr/bin/env raku
use v6.d;
use Data::Generators;

sub MAIN(
    Str $files-rx,
    Int $char-len = 8,
    Str :d($dir) = '.',
    Bool :r($recursive) = False,
    Bool :y($dry) = False,
    Int :$concurrency = 4
) {
    say "🚀 启动扫描: $dir (递归: $recursive)";
    my Channel $c = Channel.new;
    my @files;

    # 安全扫描：显示当前目录（自动系统路径分隔符）
    sub scan(IO::Path $path) {
        say "📂 扫描中: {$path.absolute}";
        my @items;
        try { @items = $path.dir };
        return unless @items;

        for @items -> $f {
            next unless $f.defined;

            if $f.f && $f.basename ~~ /<$files-rx>/ {
                @files.push: $f;
            }

            if $recursive && $f.d {
                scan($f);
            }
        }
    }

    scan($dir.IO);
    say "\n✅ 扫描完成！共找到 {+@files} 个文件";

    # 异步通道
    start {
        $c.send($_) for @files;
        $c.close;
    }

    # 并发处理
    await do ^$concurrency .map: {
        start {
            while $c.poll -> $file {
                process($file);
            }
        }
    }

    say "\n🎉 全部任务完成！";

    # 重命名（带异常捕获）
    sub process(IO::Path $real) {
        try {
            my $ext = $real.extension;
            my $new-name = random-string(
                chars => $char-len,
                ranges => ['a'..'z','A'..'Z','0'..'9']
            );

            my $new-file = $real.parent.add($new-name);
            $new-file .= extension($ext) if $ext;

            say "✅ {$real.absolute} →\n\t{$new-file.absolute}";
            rename($real, $new-file) if !$dry;

            CATCH {
                say "❌ 失败: {$real.absolute} → {.message}";
            }
        }
    }
}
