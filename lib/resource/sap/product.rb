#encoding: utf-8

module Sap
  class Product < SapAnywhereInterface
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
    def find(id)
      get(query(id))
    end

    # 通过接口获得单个数据
    # @note 通过接口获得单个数据
    # @param id [Integer] 数据id
    def posts(id)
      post(post_query(id), post_params(id).to_json)
    end
    def find_attachment(id, attachment_id)
      get(query_attchment(id, attachment_id))
    end

    #获取请求路径的请求名
    #@note 获取请求路径的请求名
    def request_name
      'Products'
    end


    def query(id = {})
      request_names = if id.present?
                        "#{request_name}/#{id}?expand=*&"
                      else
                        "#{request_name}?expand=skus&"
                      end
      {
          source: @source,
          request_name: request_names
      }
    end

    def query_attchment(id = {}, attachment_id = {})
      request_names = "#{request_name}/#{id}/Images/#{attachment_id}?"

      {
          source: @source,
          request_name: request_names
      }
    end

    def post_params(id)
      disableInventory = Hashie::Mash.new
      disableInventory.id = id
      disableInventory

    end

    def post_query(id)
      request_names = "#{request_name}/#{id}/disableInventory?"
      {
          source: @source,
          request_name: request_names
      }

    end

  end
end
