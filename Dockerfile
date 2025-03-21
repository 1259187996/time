# 使用Node.js官方镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制应用程序代码
COPY . .

# 设置环境变量
ENV NODE_ENV=production

# 启动应用 - 命令将由smithery.yaml提供
CMD ["node", "mcp_server.js"]