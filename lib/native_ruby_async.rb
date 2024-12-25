# 该文件使用 Ruby Async 插件测试并发获取数据库数据

require 'async'
require 'async/barrier'
require 'async/semaphore'

module NativeRubyAsync
  class << self
    def db_connection
      conn = SQLite3::Database.new(
        ENV.fetch('DB_NAME', 'storage/asynchronous_programming_development.sqlite3')
      )
      conn.results_as_hash = true
      conn
    end

    def get_purchase_info
      start_time = Time.now

      conn = db_connection
      total_orders_count = conn.execute("SELECT COUNT(*) FROM orders WHERE status = 1").first['COUNT(*)'].to_i
      total_sales_quantity = conn.execute("SELECT SUM(quantity) FROM orders WHERE status = 1").first['SUM(quantity)'].to_i
      avg_sales_quantity = conn.execute("SELECT AVG(quantity) FROM orders WHERE status = 1").first['AVG(quantity)'].round(0)
      top_10_sales = conn.execute(
        "SELECT product_id, SUM(quantity) as total_quantity 
         FROM orders 
         WHERE status = 1 
         GROUP BY product_id 
         ORDER BY total_quantity DESC 
         LIMIT 10"
      )
      top_10_sales_products = top_10_sales.map { |row| [row['product_id'].to_i, row['total_quantity'].to_i] }.to_h
      conn.close

      end_time = Time.now
      puts "获取数据完成，耗时 #{((end_time - start_time) * 1000).round(2)} 毫秒"

      {
        total_orders_count: total_orders_count,
        total_sales_quantity: total_sales_quantity,
        avg_sales_quantity: avg_sales_quantity,
        top_10_sales_products: top_10_sales_products
      }
    end

    def get_purchase_info_concurrently
      start_time = Time.now

      # 创建数据库连接信号量,限制最大并发连接数为 5
      semaphore = Async::Semaphore.new(5)
      barrier = Async::Barrier.new

      # 初始化变量
      total_orders_count = nil
      total_sales_quantity = nil  
      avg_sales_quantity = nil
      top_10_sales_products = nil

      Async do |task|
        # 并发执行四个查询
        barrier.async do
          semaphore.acquire do
            start_time = Time.now
            conn = db_connection
            total_orders_count = conn.execute("SELECT COUNT(*) FROM orders WHERE status = 1").first['COUNT(*)'].to_i
            conn.close
            end_time = Time.now
            puts "获取 total_orders_count 完成，耗时 #{((end_time - start_time) * 1000).round(2)} 毫秒"
          end
        end
        barrier.async do
          semaphore.acquire do
            start_time = Time.now
            conn = db_connection
            total_sales_quantity = conn.execute("SELECT SUM(quantity) FROM orders WHERE status = 1").first['SUM(quantity)'].to_i
            conn.close
            end_time = Time.now
            puts "获取 total_sales_quantity 完成，耗时 #{((end_time - start_time) * 1000).round(2)} 毫秒"
          end
        end
        barrier.async do
          semaphore.acquire do
            start_time = Time.now
            conn = db_connection
            avg_sales_quantity = conn.execute("SELECT AVG(quantity) FROM orders WHERE status = 1").first['AVG(quantity)'].round(0)
            conn.close
            end_time = Time.now
            puts "获取 avg_sales_quantity 完成，耗时 #{((end_time - start_time) * 1000).round(2)} 毫秒"
          end
        end
        barrier.async do
          semaphore.acquire do
            start_time = Time.now
            conn = db_connection
            top_10_sales = conn.execute(
              "SELECT product_id, SUM(quantity) as total_quantity 
              FROM orders 
              WHERE status = 1 
              GROUP BY product_id 
              ORDER BY total_quantity DESC 
              LIMIT 10"
            )
            top_10_sales_products = top_10_sales.map { |row| [row['product_id'].to_i, row['total_quantity'].to_i] }.to_h
            conn.close
            end_time = Time.now
            puts "获取 top_10_sales_products 完成，耗时 #{((end_time - start_time) * 1000).round(2)} 毫秒"
          end
        end
        # 等待所有查询完成
        barrier.wait
      end
      
      end_time = Time.now
      puts "获取数据完成，耗时 #{((end_time - start_time) * 1000).round(2)} 毫秒"

      {
        total_orders_count: total_orders_count,
        total_sales_quantity: total_sales_quantity,
        avg_sales_quantity: avg_sales_quantity,
        top_10_sales_products: top_10_sales_products
      }
    end
  end
end

