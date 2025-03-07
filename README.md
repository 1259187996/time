# MCP时间服务器

这是一个基于Express的时间服务API，提供多种格式的当前时间信息，支持MCP协议。

## 功能特点

- 提供ISO、Unix时间戳、人类可读等多种时间格式
- 支持MCP协议接口
- 支持CORS跨域请求
- 提供Docker容器化部署方案

## API接口

- `GET /` - 欢迎页面，显示可用的API端点
- `GET /time` - 获取所有时间格式
- `GET /time/iso` - 获取ISO格式的当前时间
- `GET /time/unix` - 获取Unix时间戳
- `GET /time/human` - 获取人类可读的时间格式
- `POST /mcp` - MCP协议接口

## 使用Docker部署

### 使用Docker Compose（推荐）

1. 确保已安装Docker和Docker Compose
2. 在项目根目录下运行：

```bash
docker-compose up -d
```

3. 服务将在后台启动，访问 http://localhost:3000 查看API文档

### 使用Dockerfile

1. 构建Docker镜像：

```bash
docker build -t mcp-time-server .
```

2. 运行容器：

```bash
docker run -d -p 3000:3000 --name mcp-time-server mcp-time-server
```

3. 访问 http://localhost:3000 查看API文档

## 本地开发

1. 安装依赖：

```bash
npm install
```

2. 启动开发服务器：

```bash
npm run dev
```

3. 生产环境启动：

```bash
npm start
```

## 环境变量

- `PORT` - 服务器监听端口（默认：3000）

## 许可证

MIT