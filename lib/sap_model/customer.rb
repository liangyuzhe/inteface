#encoding: utf-8

module SapModel

  class Customer

    #
    # 根据来源获得所有发票
    # @note 根据来源获得所有发票
    # @param source [string]
    def self.get_customers(source)
      Sap::Customer.new(source).list
    end


    # 根据来源,id获得单个发票
    # @note 根据来源,id获得单个发票
    # @param source [string]
    def self.find_customer(source, id)
      a = Sap::Customer.new(source).find(id)
    end

    # 将云店家中生成的发票上传至sap
    # @param source [string]
    # @param customer_order [Order]
    def self.upload_customer(source, customer_order)
      # p "sap_order_id是#{sap_order_id}"
      # order = SapModel::Order.find_order(source, sap_order_id)
      # p "order是#{order.count}"
      # p "order的类是#{order.class}"
      customer_id = Sap::Customer.new(source).upload(customer_order)
    end

  end

end
