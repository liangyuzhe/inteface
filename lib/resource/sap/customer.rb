#encoding: utf-8
module Sap
  class Customer < SapAnywhereInterface

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
       a = get(query(id))
       # Rails.logger.info "a的class#{a.present?}"
    end

    # 将客户数据从云店家上传到sap
    # @param customer_order [Order]
    def upload(customer_order)
      customer_id = post(query(customer_order))
    end

    #获取请求路径的请求名
    #@note 获取请求路径的请求名
    def request_name
      'Customers'
    end

    def  query(params = nil, id = nil)
      # Rails.logger.info "#{params.class}"
      # 第一个判断是用于find(id)这种情况,第二个是针对update的情况
      request_names = if params.class == Fixnum
                        # Rails.logger.info "走的是第一个"
                        "#{request_name}/#{params}?expand=*&"
                      elsif id.class == Fixnum
                        # Rails.logger.info "走的是第二个"
                        "#{request_name}/#{id}?expand=*&"
                      elsif params.class == String
                        # Rails.logger.info "走的是第三个"
                        "#{request_name}?expand=*&filter=(mobile+eq+'#{params}')&"
                      else
                        # Rails.logger.info "走的是第四个"
                        "#{request_name}?expand=*&"
                      end
      post_params = {
          source: @source,
          request_name: request_names
      }
      # p "params是#{params}"
      # p "id是#{id}"
      if params.class != Fixnum && params.class != String && params.present?
        post_params.merge!(customer: convert_to_sap_customer(params))
        # p "post_params#{post_params}"
      end
      # Rails.logger.info "++++++++#{convert_to_sap_order(params)}"
      # if params[:user_id].present?
      #   post_params.merge!(order: convert_to_sap_order(params))
      #   Rails.logger.info "post_params#{post_params}"
      # end
      post_params.merge(id: id) if id.class == Fixnum
      # p "当前参数#{post_params}"
      post_params
    end

    def convert_to_sap_customer(order)
      sap_customer = yhash

      sap_customer.customerType = 'INDIVIDUAL_CUSTOMER'

      sap_customer.stage = 'CUSTOMER'

      sap_customer.status = 'ACTIVE'

      sap_customer.marketingStatus = 'UNKNOWN'

      sap_customer.firstName = order.try(:consignee_name)

      # sap_customer.firstName = 'zxy'

      sap_customer.mobile = order.try(:consignee_phone)

      sap_customer.phone = order.try(:consignee_phone)

      sap_customer

    end


  end
end