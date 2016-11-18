#encoding: utf-8

module SapModel

  class Payment
    #
    # 根据来源获得所有收付款单
    # @note 根据来源获得所有收付款单
    # @param source [string]
    def self.get_payments(source)
      Sap::Payment.new(source).list
    end


    # 根据来源,id获得单个收付款单
    # @note 根据来源,id获得单个收付款单
    # @param source [string]
    def self.find_payment(source, id)
      Sap::Payment.new(source).find(id)
    end

    # 将云店家中生成的收付款单上传至sap
    # @param source [string]
    # @param order [Order]
    # @param invoice_id [string]
    # @param customer_id [string]
    def self.upload_payment(source, order, invoice_id, customer_id)
      invoice = SapModel::Invoice.find_invoice(source, invoice_id)
      payment_id = Sap::Payment.new(source).upload({order: order, invoice: invoice, customer_id: customer_id})
    end

  end
end