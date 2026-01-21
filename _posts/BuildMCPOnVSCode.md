


最近使用awesome copilot, 但是微软提供的是一个docker镜像，感觉不太方便。于是尝试开发一个npm的包，方便在本地使用awesome copilot的功能, 也打算开源出来，方便大家使用和贡献。

但是这个过程中遇到了一些问题，记录下来，方便以后参考。

关于调试, 由于在VSCode中, 对于npm这样的包, 都是通过stdio的方式进行通信的, 这就导致在调试过程中, 很难直接看到, 也无法debug 代码。于是我尝试了http的方式进行通信, 这样配置MCP的服务的时候, 直接访问在debug中启动的http服务, 由于是走的http协议, 后端的代码就可以直接在VSCode中调试了。

        "awesome-copilot": {
			"type": "http",
			"url": "http://localhost:8080/"
		}

不过, 在配置MCP的服务的时候, 遇到一个遇到一个问题, 卡了很久, 大概错误就是

2025-12-22 22:34:56.722 [info] Starting server awesome-copilot
2025-12-22 22:34:56.722 [info] Connection state: Starting
2025-12-22 22:34:56.722 [info] Starting server from LocalProcess extension host
2025-12-22 22:34:56.723 [info] Connection state: Running
2025-12-22 22:34:56.737 [info] 404 status sending message to http://localhost:8080/, will attempt to fall back to legacy SSE
2025-12-22 22:35:01.724 [info] Waiting for server to respond to initialize request...
2025-12-22 22:35:06.723 [info] Waiting for server to respond to initialize request...
2025-12-22 22:35:11.749 [info] Waiting for server to respond to initialize request...

一直等待响应, 后来发现是因为MCP的配置中路径问题造成的, 需要在路径后面加上mcp, 这样就可以正确访问到MCP的服务了。

        "awesome-copilot": {
			"type": "http",
			"url": "http://localhost:8080/mcp"
		}






		#关于Github Copilot的远端的自动机制.

每周任务, 自动检查更新依赖, 如果有依赖可以更新, 会自动创建issues
		https://github.com/RbBtSn0w/rbbtsn0w.github.io/issues/5

		然后在评论的地方 @copilot 让它去完成整个issues后, 全程等它去修复和更新验证, 最后就是运行Github Actions进行验证, 然后开始CR, 最后合并.