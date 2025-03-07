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
        week_of_year: now.week()
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