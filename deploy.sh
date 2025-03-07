#!/bin/bash

# MCP时间服务器 CentOS 7 部署脚本
# 此脚本将安装Node.js、配置环境并设置MCP时间服务器作为系统服务

# 确保脚本以root权限运行
if [ "$(id -u)" != "0" ]; then
   echo "此脚本需要root权限运行" 1>&2
   echo "请使用 sudo ./deploy.sh 运行" 1>&2
   exit 1
fi

# 设置变量
APP_NAME="mcp-time-server"
APP_DIR="/opt/$APP_NAME"
NODE_VERSION="14.x"
SERVICE_USER="nodejs"

echo "===== 开始部署 MCP 时间服务器 ====="

# 1. 安装必要的软件包
echo "正在安装必要的软件包..."
yum update -y
yum install -y curl git wget

# 2. 安装Node.js
echo "正在安装 Node.js $NODE_VERSION..."
curl -sL https://rpm.nodesource.com/setup_${NODE_VERSION} | bash -
yum install -y nodejs

# 检查Node.js安装
node -v
npm -v

if [ $? -ne 0 ]; then
    echo "Node.js 安装失败，请检查错误并重试"
    exit 1
fi

# 3. 创建应用目录和服务用户
echo "正在创建应用目录和服务用户..."
id -u $SERVICE_USER &>/dev/null || useradd -r -m -s /bin/bash $SERVICE_USER
mkdir -p $APP_DIR
chown -R $SERVICE_USER:$SERVICE_USER $APP_DIR

# 4. 克隆或复制应用代码
echo "正在设置应用代码..."

# 如果您有Git仓库，可以使用以下命令克隆
# git clone https://your-repo-url.git $APP_DIR

# 或者，如果您要手动创建文件，可以使用以下命令
cat > $APP_DIR/package.json << 'EOL'
{
  "name": "mcp-time-server",
  "version": "1.0.0",
  "description": "一个MCP服务器，提供当前时间信息给大模型",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "keywords": [
    "mcp",
    "time",
    "api",
    "llm"
  ],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "moment": "^2.29.4"
  }
}
EOL

cat > $APP_DIR/server.js << 'EOL'
const express = require('express');
const cors = require('cors');
const moment = require('moment');

const app = express();
const PORT = process.env.PORT || 3000;

// 启用CORS
app.use(cors());

// 解析JSON请求体
app.use(express.json());

// 根路由 - 提供简单的欢迎信息
app.get('/', (req, res) => {
  res.json({
    message: '欢迎使用MCP时间服务器',
    endpoints: {
      '/time': '获取当前时间信息',
      '/time/iso': '获取ISO格式的当前时间',
      '/time/unix': '获取Unix时间戳',
      '/time/human': '获取人类可读的时间格式'
    }
  });
});

// 获取所有时间格式
app.get('/time', (req, res) => {
  const now = moment();
  
  res.json({
    iso: now.toISOString(),
    unix: now.unix(),
    human: now.format('YYYY年MM月DD日 HH:mm:ss'),
    utc: now.utc().format('YYYY-MM-DD HH:mm:ss UTC'),
    timezone: now.format('Z'),
    day_of_week: now.format('dddd'),
    day_of_year: now.dayOfYear(),
    week_of_year: now.week(),
    is_dst: moment.isDST(),
    is_leap_year: moment([now.year()]).isLeapYear()
  });
});

// 获取ISO格式的时间
app.get('/time/iso', (req, res) => {
  res.json({ iso: moment().toISOString() });
});

// 获取Unix时间戳
app.get('/time/unix', (req, res) => {
  res.json({ unix: moment().unix() });
});

// 获取人类可读的时间格式
app.get('/time/human', (req, res) => {
  const format = req.query.format || 'YYYY年MM月DD日 HH:mm:ss';
  res.json({ human: moment().format(format) });
});

// MCP协议接口 - 符合MCP规范的时间服务
app.post('/mcp', (req, res) => {
  const now = moment();
  
  // 构建MCP响应格式
  const mcpResponse = {
    id: req.body.id || 'time-request',
    result: {
      current_time: {
        iso: now.toISOString(),
        unix: now.unix(),
        human: now.format('YYYY年MM月DD日 HH:mm:ss'),
        utc: now.utc().format('YYYY-MM-DD HH:mm:ss UTC'),
        timezone: now.format('Z'),
        day_of_week: now.format('dddd'),
        day_of_year: now.dayOfYear(),
        week_of_year: now.week(),
        is_dst: moment.isDST(),
        is_leap_year: moment([now.year()]).isLeapYear()
      }
    }
  };
  
  res.json(mcpResponse);
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`MCP时间服务器已启动，监听端口: ${PORT}`);
  console.log(`访问 http://localhost:${PORT} 查看API文档`);
});
EOL

cat > $APP_DIR/mcp_server.js << 'EOL'
const moment = require('moment');
const readline = require('readline');

// 获取环境变量中的配置
const dateFormat = process.env.DATE_FORMAT || 'YYYY年MM月DD日 HH:mm:ss';
const language = process.env.LANGUAGE || 'zh-cn';

// 设置moment语言
if (language === 'en') {
  moment.locale('en');
} else {
  moment.locale('zh-cn');
}

// 创建readline接口用于处理标准输入输出
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

// 处理MCP请求
function handleMCPRequest(request) {
  try {
    // 解析请求
    const parsedRequest = JSON.parse(request);
    const now = moment();
    
    // 构建MCP响应格式
    const mcpResponse = {
      id: parsedRequest.id || 'time-request',
      result: {
        current_time: {
          iso: now.toISOString(),
          unix: now.unix(),
          human: now.format(dateFormat),
          utc: now.utc().format('YYYY-MM-DD HH:mm:ss UTC'),
          timezone: now.format('Z'),
          day_of_week: now.format('dddd'),
          day_of_year: now.dayOfYear(),
          week_of_year: now.week(),
          is_dst: moment.isDST(),
          is_leap_year: moment([now.year()]).isLeapYear()
        }
      }
    };
    
    // 返回响应
    console.log(JSON.stringify(mcpResponse));
  } catch (error) {
    // 错误处理
    console.log(JSON.stringify({
      id: 'error',
      error: {
        code: 'invalid_request',
        message: `处理请求时出错: ${error.message}`
      }
    }));
  }
}

// 监听标准输入
rl.on('line', (line) => {
  if (line.trim()) {
    handleMCPRequest(line);
  }
});

// 处理进程退出
process.on('SIGINT', () => {
  rl.close();
  process.exit(0);
});

console.error('MCP时间服务器已启动，等待标准输入...');
EOL

# 5. 安装依赖
echo "正在安装Node.js依赖..."
cd $APP_DIR
npm install --production

# 6. 设置systemd服务
echo "正在创建systemd服务..."

cat > /etc/systemd/system/$APP_NAME.service << EOL
[Unit]
Description=MCP Time Server
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/server.js
Restart=on-failure
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$APP_NAME
Environment=NODE_ENV=production PORT=3000

[Install]
WantedBy=multi-user.target
EOL

# 7. 启用并启动服务
echo "正在启用并启动服务..."
systemctl daemon-reload
systemctl enable $APP_NAME.service
systemctl start $APP_NAME.service

# 8. 检查服务状态
echo "检查服务状态..."
systemctl status $APP_NAME.service

# 9. 配置防火墙（如果启用）
echo "正在配置防火墙..."
if systemctl is-active firewalld &>/dev/null; then
    firewall-cmd --permanent --add-port=3000/tcp
    firewall-cmd --reload
    echo "防火墙已配置，开放3000端口"
fi

# 10. 创建MCP服务器的systemd服务（可选）
echo "正在创建MCP服务器的systemd服务（用于标准输入/输出模式）..."

cat > /etc/systemd/system/$APP_NAME-mcp.service << EOL
[Unit]
Description=MCP Time Server (stdio mode)
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/mcp_server.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$APP_NAME-mcp
Environment=NODE_ENV=production DATE_FORMAT="YYYY年MM月DD日 HH:mm:ss" LANGUAGE=zh-cn

[Install]
WantedBy=multi-user.target
EOL

# 不自动启动MCP服务器，因为它需要标准输入，通常不会作为服务运行
# 但创建服务文件以便需要时可以手动启动
systemctl daemon-reload

echo "===== MCP 时间服务器部署完成 ====="
echo "Web服务器已启动在: http://$(hostname -I | awk '{print $1}'):3000"
echo "使用以下命令管理服务:"
echo "  - 查看状态: systemctl status $APP_NAME.service"
echo "  - 重启服务: systemctl restart $APP_NAME.service"
echo "  - 停止服务: systemctl stop $APP_NAME.service"
echo "  - 查看日志: journalctl -u $APP_NAME.service"
echo ""
echo "如需使用MCP标准输入/输出模式，可以手动启动:"
echo "  systemctl start $APP_NAME-mcp.service"
echo "  journalctl -f -u $APP_NAME-mcp.service"