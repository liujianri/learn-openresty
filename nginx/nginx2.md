# nginx 

## 配置指令的执行顺序
### 第一课
#### 知识点：
***
1. Nginx 的请求处理阶段共有 11 个 ，其中 3 个比较常见 执行时的先后顺序 rewrite 阶段、access 阶段以及 content 阶段
2. set 指令就是在 rewrite 阶段运行的，而 echo 指令就只会在 content 阶段运行（例1）
***
#### 示例
##### 例1
     location /test {
        set $a 32;
        echo $a;
    
        set $a 56;
        echo $a;
    }

	实际的执行顺序应当是
	    set $a 32;
	    set $a 56;
	    echo $a;
	    echo $a;

### 第二课
#### 知识点：
***
1. 运行在 rewrite 阶段的指令使用在 server 配置块中时，则会运行在一个我们尚未提及的更早的处理阶段，server-rewrite 阶段
2. 第三方模块 ngx_lua，它提供的 set_by_lua 配置指令也和 ngx_set_misc 模块的指令一样，可以和 ngx_rewrite 模块的指令混合使用（例2）
***
#### 示例
##### 例2
    location /test {
	    set $a 32;
	    set $b 56;
	    set_by_lua $c "return ngx.var.a + ngx.var.b";
	    set $equation "$a + $b = $c";

	    echo $equation;
    }

	$ curl 'http://localhost:8080/test'
    32 + 56 = 88

