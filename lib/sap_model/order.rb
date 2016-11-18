#encoding: utf-8

module SapModel

  class Order
    #
    # 根据来源获得所有订单
    # @note 根据来源获得所有订单
    # @param source [string]
    def self.get_orders(source)
      Sap::Order.new(source).list
    end


    # 根据来源,id获得单个订单
    # @note 根据来源,id获得单个订单
    # @param source [string]
    def self.find_order(source, id)
      Sap::Order.new(source).find(id)
    end

    # 将云店家中生成的订单上传至sap
    def self.upload_order(source, order, sap_customer_id)
      order_id = Sap::Order.new(source).upload(order, sap_customer_id)
    end

    # 暂时使用不到所以没有写完
    # 将云店家中订单状态有变化的订单上传至sap
    def self.upload_modified_order_to_sap(source, id, order)
      Rails.logger.info "id是#{id}"
      Rails.logger.info "order是#{order}"
      Sap::Order.new(source).update_order(order, id)
    end

    # 暂时使用不到所以没有写完
    # 为从sap接口获得的订单保存在云店家分装参数
    # @note 为从sap接口获得的订单保存在云店家分装参数
    # @param sap_product [sap_product]
    def self.query(order, source)
      status = order.try(:status)
      # yun_status = Order::Status.group_by_usage(SystemStatusGroup::Usage.const_get("#{ :admin.to_s.upcase}_QUERY_LIST"), source)

      {
          order_number: order.try(:code),
          name: order.try(:name),
          total_price: order.try(:paidTotal),
          user_id: order.try(:customer).id,

      }

    end

    # 暂时使用不到所以没有写完
    # 将从sap接口获得的订单状态转换成云店家的相应订单状态
    # @note 将从sap接口获得的订单状态转换成云店家的相应订单状态
    # @param status [string]
    # @return
    def self.convert_status(status)
      if status == CANCEL
        yun_status = Order::Status::Cancelled
      elsif status == OPEN
        yun_status = Order::Status::Awaiting_Payment
      elsif status == CLOSED
      elsif status == DRAFT
      elsif status == WAITING_APPROVAL
      elsif status == APPROVED
      end
      yun_status
    end

    # 根据来源从sap接口获得的订单保存在云店家
    # @note 根据来源从sap接口获得的订单保存在云店家
    # @param source [string]
    def self.new_or_update_all_orders_by_source(source)
      orders = Sap::Order.new(source).list
      orders.each do |order|
        options = self.query(order, source)
        self.new_or_update_order(source, order, options)
      end
    end

    # 根据来源从sap接口获得的订单保存在云店家(子方法)
    # @note 根据来源从sap接口获得的订单保存在云店家(子方法)
    # @param source [string]
    # @param sap_order [sap_order]

    def self.new_or_update_order(source, order, options)

      yun_order = ::Order.where(source: source, code: order.try(:code))
      if yun_order.present?
        yun_order.update!(options)
      else
        ::Order.create!(options)
      end

    rescue => e
      yloge e, "更新' 订单 #{order.try(:code)}, 失败"
    end

  end
end