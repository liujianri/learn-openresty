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

### 第四课
#### 知识点：
***
1. 标准 ngx_map 模块的 map 配置指令，
2. 我们的 $args 就是“自变量” x，而 $foo 则是“因变量” y，即 $foo 的值是由 $args 的值来决定的
    当 $args 的值等于 debug 的时候，$foo 变量的值就是 1，否则 $foo 的值就为 0（例子7）
3. $foo 变量在第一次读取时，根据映射规则计算出的值会被缓存；
4. map 指令是在 server 配置块之外，也就是在最外围的 http 配置块中定义的，
***
#### 示例
##### 例7
    map $args $foo {
        default     0;
        debug       1;
    }
 
    server {
        listen 8080;
 
        location /test {
            set $orig_foo $foo;
            set $args debug;
 
            echo "orginal foo: $orig_foo";
            echo "foo: $foo";
        }
    }

### 第五课
#### 知识点：
***
1. “主请求”，就是由 HTTP 客户端从 Nginx 外部发起的请求
2. “子请求”则是由 Nginx 正在处理的请求在 Nginx 内部发起的一种级联请求，“子请求”的概念是相对的，
    任何一个“子请求”也可以再发起更多的“子子请求”，甚至可以玩递归 调用（即自己调用自己）。当一个请求发起一个“子请求”的时候，按照 Nginx 的术语，习惯把前者称为后者的“父请求”（parent request）
    当 $args 的值等于 debug 的时候，$foo 变量的值就是 1，否则 $foo 的值就为 0（例子8）
3. 父子请求之间，同名变量一般也不会相互干扰 ,“主请求”以及各个“子请求”都拥有不同的变量 $var 的值容器副本（例子8）
4. 一些 Nginx 模块发起的“子请求”却会自动共享其“父请求”的变量值容器，比如第三方模块 ngx_auth_request
***
#### 示例
##### 例8
    location /main {
        set $var main;
 
        echo_location /foo;
        echo_location /bar;
 
        echo "main: $var";
    }
 
    location /foo {
        set $var foo;
        echo "foo: $var";
    }
 
    location /bar {
        set $var bar;
        echo "bar: $var";
    }

    $ curl 'http://localhost:8080/main'
    foo: foo
    bar: bar
    main: main

### 第六课
#### 知识点：
***
1. 在“子请求”中读取 $args，其“取处理程序”会很自然地返回当前“子请求”的参数串（例9）
2. 与 $args 类似，内建变量 $uri 用在“子请求”中时，其“取处理程序”也会正确返回当前“子请求”解析过的 URI
3. 类似 $request_method，内建变量 $request_uri 一般也返回的是“主请求”未经解析过的 URL，毕竟“子请求”都是在 Nginx 
    内部发起的，并不存在所谓的“未解析的”原始形式
***
#### 示例
##### 例9
    location /main {
        echo "main args: $args";
        echo_location /sub "a=1&b=2";
    }
 
    location /sub {
        echo "sub args: $args";
    }

    $ curl 'http://localhost:8080/main?c=3'
    main args: c=3
    sub args: a=1&b=2

### 第七课
#### 知识点：
***
1. 没有值的变量也有两种特殊的值：一种是“不合法”（invalid），另一种是“没找到”（not found）
2. set 指令为它创建的变量自动注册了一个“取处理程序”，将“不合法”的变量值转换为空字符串
3. Nginx 原生配置语言中是不能很方便地把‘找不到’和空字符串区分开来，不过ngx_lua 可以区分 (例10)
***
#### 示例
##### 例10
    location /test {
        content_by_lua '
            if ngx.var.arg_name == nil then
                ngx.say("name: missing")
            else
                ngx.say("name: [", ngx.var.arg_name, "]")
            end
        ';
    }

    curl 'http://localhost:8080/test'
    name: missing

    $ curl 'http://localhost:8080/test?name='
    name: []

    $ curl 'http://localhost:8080/test?name=liu'
    name: [liu]

### 第八课
#### 知识点：
***
1. Lua 里访问未创建的 Nginx 用户变量时，在 Lua 里也会得到 nil 值，而不会像先前的例子那样直接让 Nginx 拒绝加载配置（例11）
2. 在 Lua 里面读取未初始化的 Nginx 变量时得到的是空字符串 （例12）
***
#### 示例
##### 例11
    location /test {
        content_by_lua '
            ngx.say("$blah = ", ngx.var.blah)
        ';
    }

    curl 'http://localhost:8080/test'
    $blah = nil

##### 例12
    location /foo {
        content_by_lua '
            if ngx.var.foo == nil then
                ngx.say("$foo is nil")
            else
                ngx.say("$foo = [", ngx.var.foo, "]")
            end
        ';
    }
    $ curl 'http://localhost:8080/foo'
    $foo = []

