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