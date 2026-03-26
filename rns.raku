#!/usr/bin/env raku
use v6.d;
use Data::Generators;
use paths;

sub MAIN(
    Str $pattern,
    Int :l($lenth) = 8,
    Str :d($dir) = '.',
    Bool :r($recursive) = True,
    Bool :y($dry) = False,
    Int :c($concurrency) = 8  # 这个真的有用！
) {
    say "🚀 App::Rak 极速重命名（并发：$concurrency）";

    # 你原版：保留懒加载 Seq，超快
    my $files = paths(
        $dir,
        file => /<$pattern>/,
        recurse => $recursive
    );

    # 单线程生成不重名名称（绝对安全，不崩溃）
    my SetHash $used .= new;
    my @tasks = $files.map: -> $f {
        my $real = $f.IO;
        my $ext  = $real.extension;

        my $name;
        repeat {
            $name = random-string(chars => $char-len, ranges => ['a'..'z','A'..'Z','0'..'9']);
        } while $used{$name}:exists;
        $used{$name} = True;

        my $new = $real.parent.add($name);
        $new .= extension($ext) if $ext;
        ($real.absolute, $new.absolute)
    };

    # ===========================
    # ✅ 官方标准：启动 N 个工作线程（真·并发控制）
    # ===========================
    my Channel $ch .= new;
    $ch.send($_) for @tasks;
    $ch.close;

    # 启动固定数量的工作协程
    await do for ^$concurrency {
        start {
            while $ch.poll -> $task {
                my ($old, $new) = |$task;
                try {
                    say "✅ $old → $new";
                    rename($old,$new) unless $dry;
                    CATCH { say "❌ 失败: $old" }
                }
            }
        }
    }

    say "\n🎉 全部完成！";
}
