#encoding: utf-8

module SapModel

  class SalesDelivery
    #
    # 根据来源获得所有当前时间5min前的所有物流信息
    # @note 根据来源获得所有当前时间5min前的所有物流信息
    # @param source [string]
    def self.get_sale_deliveries(source)
      Sap::SalesDelivery.new(source).list
    end

    # 根据来源,id获得单个物流信息,当前时间5min前
    # @note 根据来源,id获得单个物流信息, 当前时间5min前
    # @param source [string]
    def self.find_sale_delivery(source, id)
      Sap::SalesDelivery.new(source).find(id)
    end

    # 根据来源,同步物流信息,5分钟同步一次,定时任务
    # @note 根据来源,同步物流信息,5分钟同步一次,定时任务
    # @param source [string]
    def self.new_update_all_sales_delivery
      shop_ids_map = Sap::SalesDelivery.new('').check_function_and_shop
      shop_ids_map.keys.each do |k|
        shop_ids = shop_ids_map[k].each do |shop_id|
          sales_deliveries = self.get_sale_deliveries(k)
          if sales_deliveries.present?
            sales_deliveries.each do |sale_delivery|
              self.new_update_sales_delivery(k, sale_delivery)
            end
          end
        end
      end
    end

    # 根据来源,同步物流信息,5分钟同步一次,定时任务(子方法)
    # @note 根据来源,同步物流信息,5分钟同步一次,定时任务(子方法)
    # @param source [string]
    def self.new_update_sales_delivery(source, sale_delivery)
      tracking_company = sale_delivery.try(:carrier).try(:name)
      yun_tracking_company = Express::Company.where(source: source, name: tracking_company).last
      if yun_tracking_company.present?
        yun_tracking_company_id = yun_tracking_company.id
      else
        yun_tracking_company = Express::Company.create!(source: source, name: tracking_company, code: nil, seq: nil, business_code: nil, status: Express::Company::Status::ENABLE)
        yun_tracking_company_id = yun_tracking_company.id
      end
      tracking_number = sale_delivery.try(:trackingNumber)
      sap_order_id = sale_delivery.try(:lines).first.try(:baseDocument).try(:baseId)
      order = SapModel::Order.find_order(source, sap_order_id)
      extOrderId = order.try(:extOrderId)
      #extOrderId为云店家order里面的order_number
      RequestStore.store[:source]= source
      order = ::Order.where(order_number: extOrderId).last
      order.update!(status: ::Order::Status::Shipped)
      yun_order_id = order.try(:id)
      order_fulfillment = OrderFulfillment.where(order_id: yun_order_id).last
      if order_fulfillment.present?
        order_fulfillment.update(tracking_company: tracking_company, tracking_number: tracking_number, order_id: yun_order_id, express_company_id: yun_tracking_company_id)
      else
        OrderFulfillment.create!(tracking_company: tracking_company, tracking_number: tracking_number, order_id: yun_order_id, express_company_id: yun_tracking_company_id)
      end
    rescue => e
      yloge e, "更新' 订单id #{extOrderId} 失败"
    end
  end
end