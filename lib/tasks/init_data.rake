namespace :init_data do
  desc "Generate 10 million sample orders"
  task generate_orders: :environment do
    start_time = Time.now
    puts "开始生成订单数据... #{start_time}"
    
    # 定义状态枚举值
    statuses = Order.statuses.keys
    
    # 设置批量插入的大小
    batch_size = 10000
    total_records = 10_000_000
    
    # 计算需要循环的次数
    iterations = total_records / batch_size
    
    iterations.times do |i|
      orders = []
      batch_size.times do
        orders << {
          user_id: rand(1..1000),        # 假设有 1000 个用户
          product_id: rand(1..100),       # 假设有 100 个产品
          quantity: rand(1..10),
          created_at: rand(2.years).seconds.ago,
          updated_at: rand(2.years).seconds.ago,
          status: statuses.sample
        }
      end
      
      Order.insert_all(orders)
      
      # 显示进度
      progress = ((i + 1.0) / iterations * 100).round(2)
      puts "已完成 #{progress}% (#{(i + 1) * batch_size} 条记录)"
    end

    puts "数据生成完成！总共生成了 #{Order.count} 条订单记录 #{Time.now.to_i - start_time.to_i} 秒"
  end
end
