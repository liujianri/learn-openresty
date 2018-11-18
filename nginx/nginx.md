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
##### 例子1
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

##### 例子2
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
1. 三方模块 ngx_echo 提供的 echo_exec 配置指令 进行__内部跳转__
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
##### 例子3
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

##### 例子4
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