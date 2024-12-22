# 异步编程示例项目

## 快速开始
### 安装 Ruby
- asdf install ruby 3.2.2
- asdf local ruby 3.2.2

### 安装依赖并初始化项目
- bundle install
- rails db:create
- rails db:migrate
- rake init_data:generate_orders # 生成500万条测试数据
- rails server


现在你可以访问 http://localhost:3000 查看项目了。

## 数据库说明

项目使用 SQLite3 数据库，数据文件存储在 `storage/` 目录下。测试数据包含 500 万条订单记录，包括：
- 订单状态：待支付、已支付、已完成、已取消
- 随机用户 ID 和产品 ID
- 随机创建时间（近两年内）
