# 该文件使用 Ruby Async 插件测试并发获取数据库数据

require 'async'
require 'async/barrier'
require 'async/semaphore'

module RubyAsync
  class << self
    def get_purchase_info
      start_time = Time.now
      
      total_orders_count = Order.paid.count
      total_sales_quantity = Order.paid.sum(:quantity)
      avg_sales_quantity = Order.paid.average(:quantity)
      top_10_sales_products = Order.paid.group(:product_id).order(Arel.sql("SUM(quantity) DESC")).limit(10).pluck(:product_id, :quantity).to_h
      
      end_time = Time.now
      puts "获取数据完成，耗时 #{((end_time - start_time) * 1000).round(2)} 毫秒"

      {
        total_orders_count: total_orders_count,
        total_sales_quantity: total_sales_quantity,
        avg_sales_quantity: avg_sales_quantity,
        top_10_sales_products: top_10_sales_products
      }
    end

    # 耗时与上者差不多都是4s，应为 Rails 以线程为单位来连接数据库，同个线程中只会有一个连接，需要等查询结束才能执行下一个查询
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
            total_orders_count = Order.paid.count
          end
        end
        barrier.async do
          semaphore.acquire do
            total_sales_quantity = Order.paid.sum(:quantity)
          end
        end
        barrier.async do
          semaphore.acquire do
            avg_sales_quantity = Order.paid.average(:quantity)
          end
        end
        barrier.async do
          semaphore.acquire do
            top_10_sales_products = Order.paid.group(:product_id).order(Arel.sql("SUM(quantity) DESC")).limit(10).pluck(:product_id, :quantity).to_h
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

