#!/usr/bin/env raku
use v6.d;
use Data::Generators;
use File::Find;

# 👇 这是 Raku 官方标准用法说明，自动调用！
multi USAGE() {
    say Q:to/USAGE/;
    🚀 renames 批量文件重命名工具

    用法:
        raku $*PROGRAM_NAME <正则表达式> [选项]

    必选:
        <正则表达式>    要匹配的文件格式，例如 \.log$

    选项:
        -d, --dir       扫描目录（默认：当前目录）
        -r, --recursive 递归扫描（默认：关闭）
        -y, --dry       试运行，不真实修改（默认：关闭）
        --char-len      随机名称长度（默认：8）

    示例:
        raku $*PROGRAM_NAME \.log$ -d=C:\Users\Administrator -r -y
    USAGE
}

# 👇 主函数：必选参数 + 自动 USAGE 机制
sub MAIN(      
    Str $pattern!, # 必选参数（加 ! 强制必须传）        
    Int :$char-len = 8,
    Str :d(:$dir) = '.',
    Bool :r(:$recursive) = False,
    Bool :y(:$dry) = False,
    
) {
    say "🚀 File::Find 查找文件中...";

    my $files = find(
        dir => $dir,
        name => /<$pattern>/,
        type => 'file',
        recursive => $recursive,
        keep-going => True,
    );

    await $files.race(degree => 4).map: -> $f {
        start {
            try {
                my IO::Path $real = $f;
                my $ext  = $real.extension;

                my $new-name;
                my $new-file;
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
