#encoding: utf-8
module Sap
  class Order < SapAnywhereInterface

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
      p "find中id是#{id}"
      get(query(id))
    end

    # 将订单数据从云店家上传到sap
    # sap_customer_id必须是string类型,因为从sap返回的值都是string类型的
    # @param order [Order] 订单
    # @param sap_customer_id [String] sap客户id
    # @return order_id [String] sap上订单id
    def upload(order, sap_customer_id)
      order_id = post(query(order, sap_customer_id))
    end

    # 将云店家上的订单状态与sap上的同步
    def update_order(order, id)
      patch(query(order, id))
    end

    #获取请求路径的请求名
    #@note 获取请求路径的请求名
    def request_name
      'SalesOrders'
    end

    def  query(params = nil, id = nil)
      # Rails.logger.info params[:user_id]
      # 第一个条件是满足find(id),第二个是做update时的要求
      request_names = if params.class == Fixnum || params.class == String
                        "#{request_name}/#{params}?expand=*&"
                      elsif id.class == Fixnum
                        "#{request_name}/#{id}?expand=*&"
                      else
                        "#{request_name}?expand=*&"
                      end
      # p "find中params的值是#{params.class}"
      # p "request_names是#{request_names}"
      post_params = {
          source: @source,
          request_name: request_names
      }

      # Rails.logger.info "params是#{params}"
      # Rails.logger.info "id是#{id}"
      # 为了满足post
      if params.class != Fixnum && params.class != String && params.present?
        post_params.merge!(order: convert_to_sap_order(params, id))
      end
      # Rails.logger.info "++++++++#{convert_to_sap_order(params)}"
      # if params[:user_id].present?
      #   post_params.merge!(order: convert_to_sap_order(params))
      #   Rails.logger.info "post_params#{post_params}"
      # end
      post_params.merge(id: id) if id.class == Fixnum
      Rails.logger.info "当前参数#{post_params}"
      post_params
    end

    def convert_to_sap_order(order, sap_customer_id)
      sap_order = yhash

      # sap_order.extOrderId = order.try(:id)
      # 将sap上外部订单号调整为云店家上的订单编号
      sap_order.extOrderId = order.try(:order_number)

      # 渠道
      sap_order.channel = yhash
      sap_order.channel.id = SapModel::SalesChannel.get_sales_channels(@source)
      #
      # 顾客信息 需要后续将顾客信息同步到sap 现在只能先使用对方数据库中存储的数据
      sap_order.customer = yhash
      # sap_order.customer.id = order.try(:user_id)
      # sap_order.customer.name = order.try(:consignee_name)
      sap_order.customer.id = sap_customer_id #暂时还无法改,需要把客户信息也同步到sap

      # 联系人
      # sap_order.contactPerson = ''

      # 下单时间
      sap_order.orderTime = order.try(:created_at)
      # 用户期望发货时间
      # sap_order.deliveryTime = order.try(:delivery_time)  # 这一项无法与云店家对应,sap要求是datatime类型
      # 期望运输时间(不确定)
      # sap_order.shippingTime = order.try(:deliver_goods_at) # 这一项也与云店家没有具体对应的

      # 运用方法(不确定)   # 这一项不确定是否需要填写
      # sap_order.fulfillmentMethod = yhash
      # sap_order.fulfillmentMethod = nil

      # 付款类型(需要由其他属性生成)
      sap_order.paymentType = yhash
      # sap_order.paymentType = nil
      # 增加显示sap订单中的支付类型 现在需支持在线支付和货到付款两种
      sap_order.paymentType.id = convert_payment_type(order)

      # 第三方渠道信息
      # sap_order.extMerchantInfo = yhash
      # sap_order.extMerchantInfo = nil

      # 货运公司
      # sap_order.carrier = yhash
      # sap_order.carrier = nil

      # 订单类型 (api中调整为sell_order)
      sap_order.orderType = 'SELL_ORDER'

      # 商户信息
      # sap_order.salesEmployee = yhash
      # sap_order.salesEmployee.id = order.try(:shop_id)
      # sap_order.salesEmployee.id = 2 # 需要等待把商家信息上传
      # sap_order.salesEmployee.name = ''

      # 货币 更新后exchangeRate字段删除
      sap_order.currency = yhash
      sap_order.currency.code = convert_price_unit(order)
      # sap_order.currency.isoCode = 'USD'  # 有待确认,一把这个加到请求中,就无法创建订单

      # 更新后名字从priceMethod变为pricingMethod
      sap_order.pricingMethod = 'GROSS_PRICE' # 云店家中没有对应项

      # 收货地址信息
      # billingAddress和shippingAddress对应的countryCode和stateCode在云店家中没有对应项
      sap_order.shippingAddress = yhash
      sap_order.shippingAddress.state = order.try(:province)
      sap_order.shippingAddress.cityName = order.try(:city)
      sap_order.shippingAddress.street1 = order.try(:area)
      sap_order.shippingAddress.street2 = order.try(:address)
      sap_order.shippingAddress.zipCode = order.try(:zip_code)
      sap_order.shippingAddress.mobile = order.try(:consignee_phone)
      sap_order.shippingAddress.telephone = order.try(:fixed_line_phone)
      sap_order.shippingAddress.recipientName = order.try(:consignee_name)
      sap_order.shippingAddress.displayName = "#{order.try(:consignee_name)} #{order.try(:consignee_address)} #{order.try(:consignee_phone)}"
      # sap_order.shippingAddress.displayName = order.try(:consignee_name)

      # 账单地址
      sap_order.billingAddress = yhash
      sap_order.billingAddress.state = order.try(:province)
      sap_order.billingAddress.cityName = order.try(:city)
      sap_order.billingAddress.street1 = order.try(:area)
      sap_order.billingAddress.street2 = order.try(:address)
      sap_order.billingAddress.zipCode = order.try(:zip_code)
      sap_order.billingAddress.mobile = order.try(:consignee_phone)
      sap_order.billingAddress.telephone = order.try(:fixed_line_phone)
      sap_order.billingAddress.recipientName = order.try(:consignee_name)
      sap_order.billingAddress.displayName = "#{order.try(:consignee_name)} #{order.try(:consignee_address)} #{order.try(:consignee_phone)}"
      # sap_order.billingAddress.displayName = order.try(:consignee_name)

      # 商家备注
      sap_order.processorRemark = order.try(:shop_notes)   # 不确定能否对应上
      # 客户备注
      sap_order.customerRemark = order.try(:note)

      # 订单行 inventoryUom和inventoryUomQuantity是readonly字段要省略
      # sap_order.productLines = yhash
      #   sap_order.productLines.quantity = order.product.try(:total_inventory_quantity)
        # sap_order.productLines.inventoryUomQuantity = 1

        # sap_order.productLines.inventoryUom = yhash
        #   sap_order.productLines.inventoryUom.id = 1

        # sap_order.productLines.netUnitPrice = ''
        # sap_order.productLines.grossUnitPrice = ''
        # sap_order.productLines.standardPrice = ''
        #
        # sap_order.productLines.calculationBase = 'BY_TOTAL'
        #
        # sap_order.productLines.sku = yhash
        #   sap_order.productLines.sku.id = 2
        #   sap_order.productLines.sku.name = 'producttest1'
        #   sap_order.productLines.sku.code = '001'

      # 没有加上多项子订单
      # sap_order.productLines = [{
      #     quantity: order.try(:order_items)[0].try(:quantity),
      #     netUnitPrice: '',
      #     grossUnitPrice: order.try(:order_items)[0].try(:price),
      #     standardPrice: '',
      #     calculationBase: 'BY_UNITPRICE',
      #     # grossAmount: {
      #     #     amount: '20'
      #     # },
      #     sku:{
      #         # id: order.try(:product).try(:product_variants)[0].try(:art_no),
      #         # name: order.try(:product).try(:product_variants)[0].try(:name),
      #         # code: order.try(:product).try(:product_variants)[0].try(:sku_code)
      #         id: 2,
      #         name: 'producttest1',
      #         code: 001
      #     }
      #                           }]

      # 这样添加会将order_items的信息全添加进去
      # sap_order.productLines = [
      #     order.try(:order_items).each do |child_order|
      #       {
      #           quantity: child_order.try(:quantity),
      #           netUnitPrice: '',
      #           grossUnitPrice: child_order.try(:price),
      #           standardPrice: '',
      #           calculationBase: 'BY_UNITPRICE',
      #           sku: {
      #               id: 2,
      #               name: 'producttest1',
      #               code: 001
      #           }
      #       }
      #     end
      # ]


      sap_order.productLines = order.try(:order_items).try(:map) do |child_order|
        {
            quantity: child_order.try(:quantity),
            netUnitPrice: child_order.try(:price),
            # sapapi更新后netUnitPrice作为单价了,原先是grossUnitPrice
            # grossUnitPrice: child_order.try(:price),
            grossUnitPrice: '',
            standardPrice: '',
            calculationBase: 'BY_UNITPRICE',
            sku: {
                id: '',
                name: '',
                # code: '3-Y1'
                code: child_order.try(:product_variant).try(:art_no)
            }
        }
      end


      # 退货行 现在没用到退货
      # sap_order.returnLines = yhash

      # 物流行
      sap_order.shippingLines = [{
            netAmount: {
                amount: order.try(:post_fee)
            },
            grossAmount: {
              amount: order.try(:post_fee)
            }
        }]

      # 退货原因
      sap_order.returnReason = order.try(:return_note)

      # 支付方式
      sap_order.paymentTerm = yhash
      sap_order.paymentTerm.id = order.try(:payment_type)
      sap_order.paymentTerm.name = ::Order::PaymentType.get_i18n_desc_by_value_through_constant_name order.try(:payment_type).to_i

      # sap_order = {
      #     # code: order.try(:order_number)
      #     channel: {
      #         id: 2
      #     },
      #     customer: {
      #         id: order.try(:user_id),
      #         name: order.try(:consignee_name),
      #     },
      #     salesEmployee: {
      #         id: order.try(:shop_id)
      #     },
      #     currency: {
      #         code: order.try(:price_unit)
      #         # isoCode: order.try(:price_unit)
      #     },
      #     # 这一项云店家中没有对应的
      #     priceMethod: 'GROSS_PRICE',
      #     productLines: {
      #       quantity: order.product.try(:total_inventory_quantity),
      #       inventoryUomQuantity: 1,
      #       inventoryUom: {
      #           id: 1
      #       },
      #       calculationBase: 'BY_TOTAL',
      #       sku: {
      #           id: '2',
      #           name: 'producttest1',
      #           code: '001'
      #       }
      #     },
      #     paymentTerm: {
      #         id: order.try(:payment_type),
      #         name: '支付宝'
      #     }
      # }

      sap_order
    end

    # # 转换云店家中的货币单位,对应上sap上的货币
    # # params 类型:order
    # # return string, string
    # def convert_price_unit(order)
    #   if order.try(:price_unit) == 1
    #     code = 'RMB'
    #     isoCode = 'CNY'
    #   else
    #     code = 'USD'
    #     isoCode = 'USD'
    #   end
    #   return code
    # end


  end
end