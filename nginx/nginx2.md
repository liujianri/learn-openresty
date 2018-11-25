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

### 第三课
#### 知识点：
***
1. 运行在同一个请求处理阶段，分属不同模块的配置指令也可能会分开独立运行，在单个请求处理阶段内部，一般也会以
	Nginx模块为单位进一步地划分出内部子阶段
2. Nginx 的 rewrite 阶段是一个比较早的请求处理阶段，这个阶段的配置指令一般用来对当前请求进行各种修改（比如对 URI 和 URL 参数进行改写），或者创建并初始化一系列后续处理阶段可能需要的 Nginx 变量。rewrite_by_lua 这样的指令可以嵌入任意复杂的 Lua 代码 可以用来读取请求体，或者访问数据库等远方服务
3. rewrite阶段之后，有一个名叫access的请求处理阶段,在access阶段运行的配置指令多是执行访问控制性质的任务，
	比如检查用户的访问权限，检查用户的来源 IP 地址是否合法
4. 为了避免阅读配置时的混乱，我们应该总是让指令的书写顺序和它们的实际执行顺序保持一致。

## 第四课
#### 知识点：
***
1. 从性能上 例4比例3 要快大约一个数量级，但是在例3中 lua 代码可以做更多的事情
***
#### 示例
##### 例3
    location /hello {
        access_by_lua '
            if ngx.var.remote_addr == "127.0.0.1" then
                return
            end
 
            ngx.exit(403)
        ';
 
        echo "hello world";
    }

##### 例4
     location /hello {
        allow 127.0.0.1;
        deny all;
 
        echo "hello world";
    }

## 第五课
#### 知识点：
***
1.  Nginx 的 content 阶段是所有请求处理阶段中最为重要的一个，因为运行在这个阶段的配置指令一般都肩负着生成“内容”（content）并输出 HTTP 响应的使命 
2. content 阶段属于一个比较靠后的处理阶段，运行在先前介绍过的 rewrite 和 access 这两个阶段之后
3. 例5运行顺序 就是书写的顺序
4. location 中同时使用多个模块的 content 阶段指令时，只有其中一个模块能成功注册“内容处理程序”，每一个 location 只能有一个“内容处理程序”
	例6
5. ngx_proxy 模块的 proxy_pass 指令和 echo 指令也不能同时用在一个 location 中，因为它们也同属 content 阶段 例7,不过 可以将
	例子中 echo 改成 echo_before_body 和 echo_after_body  就可以按照预想输出
***
##### 例5
    location /test {
        # rewrite phase
        set $age 1;
        rewrite_by_lua "ngx.var.age = ngx.var.age + 1";
 
        # access phase
        deny 10.32.168.49;
        access_by_lua "ngx.var.age = ngx.var.age * 3";
 
        # content phase
        echo "age = $age";
    }

    $ curl 'http://localhost:8080/test'
    age = 6

##### 例6
    location /test {
        echo hello;
        content_by_lua 'ngx.say("world")';
    }

    $ curl 'http://localhost:8080/test'
    world

##### 例7
    ? location /test {
    ?     echo "before...";
    ?     proxy_pass http://127.0.0.1:8080/foo;
    ?     echo "after...";
    ? }
    ?
    ? location /foo {
    ?     echo "contents to be proxied";
    ? }

    $ curl 'http://localhost:8080/test'
    contents to be proxied

## 第六课
#### 知识点：
***
1. 当一个 location 中未使用任何 content 阶段的指令，即没有模块注册“内容处理程序”时， 当前请求的 URI 
2.  ngx_index 和 ngx_autoindex 模块都只会作用于那些 URI 以 / 结尾的请求，例如请求 GET /cats/，而对于不以 / 结尾的请求则会直接忽略，同时把处理权移交给 content 阶段的下一个模块。而 ngx_static 模块则刚好相反，直接忽略那些 URI 以 / 结尾的请求
3. 例8 解析  content 阶段的 ngx_index 模块在 /var/www/ 下找到了 index.html，于是立即发起一个到 /index.html 位置的“内部跳转
重新为 /index.html 这个新位置匹配 location 配置块时，location /index.html 的优先级要高于 location /，因为 location 块按照 URI 前缀来匹配时遵循所谓的“最长子串匹配语义”。这样，在进入 location /index.html 配置块之后，又重新开始执行 rewrite 、access、以及 content 等阶段。最终输出 a = 32
***
#### 示例
##### 例8
    location / {
        root /var/www/;
        index index.html;
    }
 
    location /index.html {
        set $a 32;
        echo "a = $a";
    }

    $ curl 'http://localhost:8080/'
    a = 32

## 第七课
#### 知识点：
***
1. 例9 解析：location / 中没有使用运行在 content 阶段的模块指令，于是也就没有模块注册这个 location 的“内容处理程序”，处理权便自动落到了在 content 阶段“垫底”的那 3 个静态资源服务模块。首先运行的 ngx_index 和 ngx_autoindex 模块先后看到当前请求的 URI，/index.html 和 /hello.html，并不以 / 结尾，于是直接弃权，将处理权转给了最后运行的 ngx_static 模块。ngx_static 模块根据 root 指令指定的“文档根目录”（document root），分别将请求 URI /index.html 和 /hello.html 映射为文件系统路径 /var/www/index.html 和 /var/www/hello.html，在确认这两个文件存在后，将它们的内容分别作为响应体输出，并自动设置 Content-Type、Content-Length 以及 Last-Modified 等响应头
2. 没有配置 root 指令，所以在访问这个接口时，Nginx 会自动计算出一个缺省的“文档根目录”。该缺省值是取所谓的“配置前缀”（configure prefix）路径下的 html/ 子目录
***
#### 示例
##### 例9
	
	在本机的 /var/www/ 目录下创建两个文件，一个文件叫做 index.html，内容是一行文本 this is my home；另一个文件叫做 hello.html，内容是一行文本 hello world

    location / {
        root /var/www/;
    }

     $ curl 'http://localhost:8080/index.html'
    this is my home
 
    $ curl 'http://localhost:8080/hello.html'
    hello world


## 第八、九、十、十一课
#### 知识点：
***
1.Nginx 处理请求的过程一共划分为 11 个阶段，按照执行顺序依次是 post-read、server-rewrite、find-config、rewrite、post-rewrite、preaccess、access、post-access、try-files、content 以及 log.
2. try_files 指令接受两个以上任意数量的参数，每个参数都指定了一个 URI. 这里假设配置了 N 个参数，则 Nginx 会在 try-files 阶段，依次把前 N-1 个参数映射为文件系统上的对象（文件或者目录），然后检查这些对象是否存在。一旦 Nginx 发现某个文件系统对象存在，就会在 try-files 阶段把当前请求的 URI 改写为该对象所对应的参数 URI（但不会包含末尾的斜杠字符，也不会发生 “内部跳转”）。如果前 N-1 个参数所对应的文件系统对象都不存在，try-files 阶段就会立即发起“内部跳转”到最后一个参数（即第 N 个参数）所指定的 URI
***
#### 示例
##### 例10

	location ~* /api/lesson/(.*) {
        try_files $uri /htmall/fastadmin/public/index.php/lesson/$1$2?$query_string;
        log_by_lua_file /home/git/webapi/lua/service/logger/collect.lua;
    }