#encoding: utf-8
module Sap
  class Payment < SapAnywhereInterface

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
    # @param payment_order [Order] 订单
    def upload(payment_order)
      payment_id = post(query(payment_order))
    end

    #获取请求路径的请求名
    #@note 获取请求路径的请求名
    def request_name
      'Payments'
    end

    def  query(params = {}, id = {})
      # Rails.logger.info params[:user_id]
      request_names = if params.class == Fixnum
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
      # Rails.logger.info "params是#{params}"
      # Rails.logger.info "id是#{id}"
      if params.class != Fixnum && params.present?
        post_params.merge!(payment: convert_to_sap_payment(params))
        # Rails.logger.info "post_params#{post_params}"
      end
      post_params.merge(id: id) if id.class == Fixnum
      # Rails.logger.info "当前参数#{post_params}"
      post_params
    end

    def convert_to_sap_payment(params)

      sap_payment = yhash
      # 汇率
      sap_payment.exchangeRate = 1

      # 顾客信息
      sap_payment.customer = yhash
      sap_payment.customer.id = params[:customer_id] #暂时还无法改,需要把客户信息也同步到sap

      # 联系人信息
      # sap_payment.contactPerson = yhash
      # sap_payment.contactPerson.id = ''

      # 参考编号
      sap_payment.referenceNumber = nil

      # 订单的时间
      sap_payment.postingTime = params[:order].try(:created_at)

      # 付款评价
      sap_payment.remark = nil

      # 货币单位
      sap_payment.currency = yhash
      # sap_payment.currency.code = params[:order][:currency][:code]
      sap_payment.currency.code = convert_price_unit(params[:order])
      # sap_payment.currency.isoCode = params[:order][:currency][:isoCode]

      # 收付款行
      sap_payment.paymentLines = [
          {
              transactionDocument: {
                id: params[:invoice][:id],
                type: 'Invoice'   # 必须是Invoice, CreditMemo, Prepayment
              },
              appliedAmount: {
                amount: params[:invoice][:grossTotal][:amount] # 订单总金额
              }
          }
      ]

      # 付款方式行
      sap_payment.paymentMethodLines = []
      cash_payment_method_line = yhash
      cash_payment_method_line.paymentMethod = yhash
      cash_payment_method_line.paymentMethod.id = 1
      cash_payment_method_line.paymentMethod.name = '现金'
      cash_payment_method_line.paymentMethod.type = 'CASH'
      cash_payment_method_line.amount = yhash
      cash_payment_method_line.amount.amount = params[:order][:pay_cash_total_price]
      sap_payment.paymentMethodLines << cash_payment_method_line
      # 需要在sap平台上添加积分付款方式,不然这里是按照paymentMethod的id来取付款方式的
      if !params[:order][:point_pay_total_price].zero?
        point_payment_method_line = yhash
        point_payment_method_line.paymentMethod = yhash
        point_payment_method_line.paymentMethod.id = 2
        point_payment_method_line.paymentMethod.name = '积分'
        point_payment_method_line.paymentMethod.type = 'OTHERS'
        point_payment_method_line.amount = yhash
        point_payment_method_line.amount.amount = params[:order][:point_pay_total_price]
        sap_payment.paymentMethodLines << point_payment_method_line
      end

      sap_payment

    end

  end
end