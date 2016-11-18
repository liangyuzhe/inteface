#encoding: utf-8
module Sap
  class Invoice < SapAnywhereInterface

    #
    # 对象初始化方法(初始化来源)
    # @note 对象初始化方法(初始化来源)
    # @param source [string]
    def initialize(source)
      @source = source
    end

    # 通过接口获得一堆数据
    # @note 通过接口获得一堆数据
    # @param source [string] 来源
    # @param request_name [string] 请求资源名
    def list
      get(query)
    end

    # 通过接口获得单个数据
    # @note 通过接口获得单个数据
    # @param id [Integer] 数据id
    def find(id)
      get(query(id))
    end

    # 将收付款单数据从云店家上传到sap
    # @param invoice_order [string]
    def upload(invoice_order)
      invoice_id = post(query(invoice_order))
    end

    #获取请求路径的请求名
    #@note 获取请求路径的请求名
    def request_name
      'SalesInvoices'
    end

    def  query(params = {}, id = {})
      # Rails.logger.info params[:user_id]
      request_names = if params.class == Fixnum || params.class == String
                        "#{request_name}/#{params}?expand=*&"
                      elsif id.class == Fixnum
                        "#{request_name}/#{id}?expand=*&"
                      else
                        "#{request_name}?expand=*&"
                      end
      post_params = {
          source: @source,
          request_name: request_names
      }
      p "params是#{params}"
      p "id是#{id}"
      if params.class != Fixnum && params.class != String && params.present?
        post_params.merge!(invoice: convert_to_sap_invoice(params))
        p "post_params#{post_params}"
      end
      post_params.merge(id: id) if id.class == Fixnum
      # p "当前参数#{post_params}"
      post_params
    end

    def convert_to_sap_invoice(order)
      sap_invoice = yhash

      # 汇率
      sap_invoice.exchangeRate = 1

      # 过账时间
      sap_invoice.postingTime = order.try(:orderTime)

      # 到期时间
      sap_invoice.dueTime = order.try(:orderTime)

      # 备注
      sap_invoice.remark = "来源订单编号[#{order.try(:docNumber)}]"

      # 联系人
      # sap_invoice.contactPerson = yhash
      # sap_invoice.contactPerson.id = ''

      # 账单地址
      sap_invoice.billingAddress = yhash
      sap_invoice.billingAddress.state = order.try(:billingAddress).try(:state)
      sap_invoice.billingAddress.cityName = order.try(:billingAddress).try(:cityName)
      sap_invoice.billingAddress.street1 = order.try(:billingAddress).try(:street1)
      sap_invoice.billingAddress.street2 = order.try(:billingAddress).try(:street2)
      sap_invoice.billingAddress.zipCode = order.try(:billingAddress).try(:zipCode)
      sap_invoice.billingAddress.mobile = order.try(:billingAddress).try(:mobile)
      sap_invoice.billingAddress.telephone = order.try(:billingAddress).try(:telephone)
      sap_invoice.billingAddress.recipientName = order.try(:billingAddress).try(:recipientName)
      sap_invoice.billingAddress.displayName = order.try(:billingAddress).try(:displayName)

      # 发票行
      sap_invoice.invoiceLines = []
      order.try(:productLines).try(:each) do |child_product_lines|
        child_invoice_lines = yhash
        child_invoice_lines.baseDocument = yhash
        child_invoice_lines.baseDocument.baseId = order.try(:id)
        child_invoice_lines.baseDocument.baseNumber = nil
        child_invoice_lines.baseDocument.baseType = nil
        child_invoice_lines.baseDocument.baseLineId = child_product_lines.try(:id)
        child_invoice_lines.baseDocument.baseLineNumber = nil
        child_invoice_lines.remark = nil

        sap_invoice.invoiceLines << child_invoice_lines
      end

      # 物流行
      sap_invoice.shippingLines = [
          {
              baseDocument: {
                  baseId: order.try(:id),
                  baseNumber: nil,
                  baseType: nil,
                  baseLineId: order.try(:shippingLines).try(:first).try(:id),
                  baseLineNumber: nil
              },
              remark: nil
          }
      ]

      # # 付款信息
      sap_invoice.paymentTerm = yhash
      sap_invoice.paymentTerm.id = order.try(:paymentTerm).try(:id)
      sap_invoice.paymentTerm.name = order.try(:paymentTerm).try(:name)

      sap_invoice

    end

  end
end