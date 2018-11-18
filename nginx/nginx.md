# nginx 

## 变量 
***
1. 使用标准 ngx_rewrite 模块的 set 配置指令对变量  进行了赋值操作
2. 使用第三方 ngx_echo 模块的 echo 配置指令将变量的值作为当前请求的响应体输出
3. Nginx 变量名的可见范围虽然是整个配置，但每个请求都有所有变量的独立副本，或者说都有各变量用来存放值的容器的独立副本，彼此互不干扰
***
### 示例
#### 例子2
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

#### 例子2
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