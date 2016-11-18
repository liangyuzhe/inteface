#encoding: utf-8

module Sap
  class SalesPriceList < SapAnywhereInterface
    # include InterfaceBase

    #
    # 对象初始化方法(初始化来源)
    # @note 对象初始化方法(初始化来源)
    # @param source [string]
    def initialize(source)
      @source = source
    end


    #
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
    def find(id, params = {})
      get(query(id, params))
    end

    #获取请求路径的请求名
    #@note 获取请求路径的请求名
    def request_name
      'SalesPriceLists'
    end

    def query(id = {}, params = {})
      request_names = if id.present?
                        skuid = params[:skuid]
                          "#{request_name}/#{id}/SKUPrice/#{skuid}?expand=*&"
                        # end
                      else
                        "#{request_name}?"
                      end
      {
          source: @source,
          request_name: request_names
      }
    end

  end
end
