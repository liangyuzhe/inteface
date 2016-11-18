#encoding: utf-8
module Sap
  class User < SapAnywhereInterface

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

    #获取请求路径的请求名
    #@note 获取请求路径的请求名
    def request_name
      'Users'
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
      # p "params是#{params}"
      # p "id是#{id}"
      # if params.class != Fixnum && params.class != String && params.present?
      #   p " dasdaada"
      #   post_params.merge!(customer: convert_to_sap_customer(params))
      #   p "post_params#{post_params}"
      # end
      # Rails.logger.info "++++++++#{convert_to_sap_order(params)}"
      # if params[:user_id].present?
      #   post_params.merge!(order: convert_to_sap_order(params))
      #   Rails.logger.info "post_params#{post_params}"
      # end
      # p "++---+++#{}"
      post_params.merge(id: id) if id.class == Fixnum
      # p "当前参数#{post_params}"
      post_params
    end

  end
end