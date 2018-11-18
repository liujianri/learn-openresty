# nginx 

## 变量

### 第一课
#### 知识点：
***
1. 使用标准 ngx_rewrite 模块的 set 配置指令对变量  进行了赋值操作
2. 使用第三方 ngx_echo 模块的 echo 配置指令将变量的值作为当前请求的响应体输出
3. Nginx 变量名的可见范围虽然是整个配置，但每个请求都有所有变量的独立副本，或者说
    都有各变量用来存放值的容器的独立副本，彼此互不干扰
***
#### 示例
##### 例1
    geo $dollar {
        default "$";
    }

    server {
        listen 8080;

        location /test {
            echo "This is a dollar sign: $dollar";
        }
    }

    $ curl 'http://localhost:8080/test'
    This is a dollar sign: $

##### 例2
    server {
        listen 8080;

        location /foo {
            echo "foo = [$foo]";
        }

        location /bar {
            set $foo 32;
            echo "foo = [$foo]";
        }
    }

    $ curl 'http://localhost:8080/foo'
    foo = []

    $ curl 'http://localhost:8080/bar'
    foo = [32]

    $ curl 'http://localhost:8080/foo'
    foo = []

### 第二课
#### 知识点：
***
1. 三方模块 ngx_echo 提供的 echo_exec 配置指令 进行 **内部跳转**
2. “内部跳转”，就是在处理请求的过程中，于服务器内部，从一个 location 跳转到另一个 location 的过程。
    这不同于利用 HTTP 状态码 301 和 302 所进行的“外部跳转 （例子3）
3. Nginx 变量值容器的生命期是与当前正在处理的请求绑定的，而与 location 无关 （例子3）
4. 标准 ngx_rewrite 模块的 rewrite 配置指令其实也可以发起“内部跳转”  rewrite ^ /bar;
5. nginx 有 Nginx 核心和各个 Nginx 模块提供的“预定义变量”，或者说“内建变量”（builtin variables）（例子4）。
6. ngx_http_core 模块 群变量，即名字以 arg_ 开头的所有变量，我们估且称之为 $arg_XXX 变量群 XXX不区分大小写（例子4）
    ngx_http_core 模块有更多的变量群，另外许多内建变量都是只读的
7. 可使用第三方 ngx_set_misc 模块提供的 set_unescape_uri 进行解码
***
#### 示例
##### 例3
    server {
        listen 8080;
 
        location /foo {
            set $a hello;
            echo_exec /bar;
        }
 
        location /bar {
            echo "a = [$a]";
        }
    }

    $ curl localhost:8080/foo
    a = [hello]

##### 例4
    server {
        listen 8080;
 
        location /test {
            echo "uri = $uri";
            echo "request_uri = $request_uri";
        }

        location /test2 {
            echo "name: $arg_name";
            echo "class: $arg_class";
        }

    }

    $ curl localhost:8080/foo
    a = [hello]

    $ curl 'http://localhost:8080/test?name=Tom&class=3'
    name: Tom
    class: 3

### 第三课
#### 知识点：
***
1. 一些内建变量是支持改写，
2. $args. 这个变量在读取时返回当前请求的 URL 参数串（例子5）
3. 对 $args 的修改会影响到所有部分的功能,如：set $args "a=5"， echo "$args_a" 无论请求参数是啥 会得到结果是 5 ；
4. 像 $arg_XXX 这样具有无数变种的变量群，是“未索引的”。当读取这样的变量时，
    其实是它的“取处理程序”在起作用，即实时扫描当前请求的 URL 参数串，提取出变量名所指定的 URL 参数的值
5. Nginx 根本不会事先就解析好 URL 参数串，而是在用户读取某个 $arg_XXX 变量时，调用其“取处理程序”，即时去扫描 URL 参数串（例子6）。
***
#### 示例
##### 例5
    location /test {
        set $orig_args $args;
        set $args "a=3&b=4";
 
        echo "original args: $orig_args";
        echo "args: $args";
    }

    $ curl 'http://localhost:8080/test'
    original args: 
    args: a=3&b=4
 
    $ curl 'http://localhost:8080/test?a=0&b=1&c=2'
    original args: a=0&b=1&c=2
    args: a=3&b=4

##### 例6  代理模块 ngx_proxy
    server {
        listen 8080;
 
        location /test {
            set $args "foo=1&bar=2";
            proxy_pass http://127.0.0.1:8081/args;
        }
    }
 
    server {
        listen 8081;
 
        location /args {
            echo "args: $args";
        }
    }
    
    $ curl 'http://localhost:8080/test?blah=7'
    args: foo=1&bar=2