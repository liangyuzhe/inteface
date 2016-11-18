#encoding: utf-8

module SapModel

  class Invoice

    #
    # 根据来源获得所有发票
    # @note 根据来源获得所有发票
    # @param source [string]
    def self.get_invoices(source)
      Sap::Invoice.new(source).list
    end


    # 根据来源,id获得单个发票
    # @note 根据来源,id获得单个发票
    # @param source [string]
    def self.find_invoice(source, id)
      Sap::Invoice.new(source).find(id)
    end

    # 将云店家中生成的发票上传至sap
    # @param source [string]
    # @param sap_order_id [string] sap平台上订单的id
    def self.upload_invoice(source, sap_order_id)
      # p "sap_order_id是#{sap_order_id}"
      order = SapModel::Order.find_order(source, sap_order_id)
      # p "order是#{order}"
      # p "order的类是#{order.class}"
      invoice_id = Sap::Invoice.new(source).upload(order)
    end

  end

end
