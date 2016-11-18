#encoding: utf-8

module Sap
  class SapAnywhereInterface

    module Code

      UNAUTHORIZED = 401

      FORBIDDEN = 403

      BADREQUEST = 400
    end

    #
    # 根据来源获得sap的access_token
    # @note 根据来源获得sap的access_token
    # @param source [string]
    def get_access_token(params)

      Rails.cache.read([SapAnywhereAccount.class_name, params[:source]])

    end
    #
    #
    # 获得get请求的数据
    # @note 获得get请求的数据
    # @param source [string] 来源
    # @param request_name [string] 请求资源名 /Products   /Products/{id}  /Products/count /Products/CustomFieldsMeta
    # @return 解析后的数据
    def get(params, time = 0)

      get_params = get_access_token_url(params)

      response = RestClient.get get_params

      handle_response(response)

    rescue => e
      check_access_token(e.try(:response), params)
      if response.blank? || [Code::UNAUTHORIZED, Code::FORBIDDEN].include?(e.try(:response).code)
        time += 1
        Rails.logger.info "重新发出请求"
        if time < 4
        Rails.logger.info "time#{time}"
         retry
        end
      elsif Sap::SapAnywhereInterface::Code::BADREQUEST == e.try(:response).code
        Rails.logger.info "请求的链接有误(例如:错误的id)"
      end
    end

    #
    # post请求的创建的数据
    # @note post请求的创建的数据
    # @param source [string] 来源
    # @param request_name [string] 请求资源名
    # @param object [json] 对象

    def post(params)
      # p "传到post中的参数是#{params}"
      url = get_access_token_url(params)
      # Rails.logger.info "URL地址是#{url}"
      access_token = get_access_token(params)
      # Rails.logger.info "access_token是#{access_token}"

      options = params.values.select(&:present?).third.to_json

      # p "optionstojson后是#{params.values.select(&:present?).third.to_hash}"

      response = RestClient.post(url, options, :content_type => :json)

      return response

      # Rails.logger.info response
      #
      # Rails.logger.info "end=="
      #
      # Rails.logger.info '返回的结果'
      #
      # Rails.logger.info "order的值#{params[:order]}是是是"
      # Rails.logger.info "response返回值#{response}是是是"
      # handle_response(response) # post请求返回的是数字id,调用handle_response会报错
    rescue => e
      # Rails.logger.info body.ai
      yloge e
      Rails.logger.info "错误信息#{e}是是是"
      check_access_token(e.try(:response), params)

    # def post(params_url, params)
    #   Rails.logger.info "params#{params}"
    #   response = RestClient.post(get_access_token_url(params_url), params)
    #
    #   response_json = JSON.parse(response)
    #   handle_response(response)
    # rescue => e
    #
    #   check_access_token(e.try(:response), params_url)

      # puts e.message
      if [Code::UNAUTHORIZED, Code::FORBIDDEN].include?(e.try(:response).code)

        Rails.logger.info "重新发出请求"
        #retry
      elsif Sap::SapAnywhereInterface::Code::BADREQUEST == e.try(:response).code
        Rails.logger.info "请求的链接有误(例如:错误的id)"
      end

    end

    #
    # delete请求的的数据
    # @note post请求的的数据
    # @param source [string] 来源
    # @param request_name [string] 请求资源名
    # @param id [Integer] id

    def delete(params)

      response = RestClient.delete get_access_token_url(params)
      handle_response(response)
    rescue => e

      check_access_token(e.try(:response), params)
      # puts e.message
      if [Code::UNAUTHORIZED, Code::FORBIDDEN].include?(e.try(:response).code)

        Rails.logger.info "重新发出请求"
        retry
      elsif Sap::SapAnywhereInterface::Code::BADREQUEST == e.try(:response).code
        Rails.logger.info "请求的链接有误(例如:错误的id)"
      end
    end

    #
    # patch请求更新的数据
    # @note patch请求更新的数据
    # @param source [string] 来源
    # @param request_name [string] 请求资源名
    # @param id [Integer] id
    # @param object [json] 对象

    def patch(params)

      response = RestClient.patch(get_access_token_url(params), params.to_json, accept: :json)
      handle_response(response)
    rescue => e

      check_access_token(e.try(:response), params)
      # puts e.message
      if [Code::UNAUTHORIZED, Code::FORBIDDEN].include?(e.try(:response).code)

        Rails.logger.info "重新发出请求"
        retry
      elsif Sap::SapAnywhereInterface::Code::BADREQUEST == e.try(:response).code
        Rails.logger.info "请求的链接有误(例如:错误的id)"
      end
    end

    #
    # 对于RestClient的返回值进行数据分析
    # @note 对于RestClient的返回值进行数据分析
    # @param response [string]
    def handle_response(response)
      decode_data = MultiJson.decode response.body
      if decode_data.kind_of? Array
        decode_data.map do |m|
          yhash m
        end
      else
        yhash decode_data
      end

    end

    #
    # 得到请求url
    # @note 得到请求url
    # @param source [string] 来源
    # @param request_name [string] 请求资源名
    def get_access_token_url(params)
      access_token = get_access_token(params)
      # Rails.logger.info "获得的access_token是#{access_token}"
      url = "#{SapSetting.sap_request_url}#{params[:request_name]}access_token=#{access_token}"
      Rails.logger.info "#{url}"
      return url

    end

    #
    # 根据http返回code对access_token进行验证
    # @note 根据http返回code对access_token进行验证
    # @param response [string] 来源
    def check_access_token(response, params)
      #
      # Rails.logger.info "code是#{response.try(:code)}"

      if response.blank? || [Code::UNAUTHORIZED, Code::FORBIDDEN].include?(response.code)
        sap = SapAnywhereAccount.where(source: params[:source]).last
        response = RestClient.get sap.get_access_token_url

        body = self.handle_response(response.body)

        sap.update!(access_token: body.access_token)

        Rails.cache.write([SapAnywhereAccount.class_name, params[:source]], body.access_token)


      end

    end

    # 转换云店家中的货币单位,对应上sap上的货币
    # params 类型:order
    # return string, string
    def convert_price_unit(order)
      if order.try(:price_unit) == 1
        code = 'RMB'
        isoCode = 'CNY'
      else
        code = 'USD'
        isoCode = 'USD'
      end
      return code
    end

    # 转换云店家的支付类型,对应上sap的支付类型
    # params 类型Order
    # return string sap上支付类型的对应id
    def convert_payment_type(order)
      if order.try(:payment_type) == ::Order::PaymentType::Alipay
        # 在线支付
        id = '1'
      elsif order.try(:payment_type) == ::Order::PaymentType::CASH_ON_DELIVERY
        # 货到付款
        id = '2'
      end
      id
    end

    # 功能验证
    # @note 功能验证a
    def check_function_and_shop
      source_list = SystemSource.option_for_select
       shop_ids_map = source_list.each_with_object({}) do |source_list, map|
        source = source_list.source
        accounts = SapFunctionAccount.where(source: source, function: self.to_s.split(':').third, status: SapFunctionAccount::Status::ENABLED)
        key = source
        if accounts.present?
          Rails.logger.info "aaaaaaaa"
          map[key] = accounts.map(&:shop_id)
        end
      end
    end

  end
end