#encoding: utf-8

module Sap
  class SalesDelivery < SapAnywhereInterface
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
      'SalesDeliveries'
    end


    # 设置请求的路径,过滤条件为当前时间的前12小时生成的物流
    # @note 设置请求的路径,过滤条件为当前时间的前12小时生成的物流
    #  @param id [Integer]物流id
    def query(id = {}, params = {})
      #临时先这样写 因为sap的物流时间有bug
      # before_now_five_min = (Time.now.strftime('%M').to_i).to_s
      before_now_hour = Time.now.strftime('%H').to_i
      before_now_day = Time.now.strftime('%d').to_i
      # if before_now_five_min < 0
      #   before_now_five_min = (before_now_five_min + 60).to_s
      #   before_now_hour = (before_now_hour - 1).to_s
      # else
      #   before_now_five_min = before_now_five_min.to_s
      #   before_now_hour = before_now_hour.to_s
      # end
      if before_now_hour >= 12
        before_now_hour = (before_now_hour - 12).to_s
        before_now_hour = "0#{before_now_hour}"
        before_now_day = before_now_day.to_s
      else
        before_now_hour = (before_now_hour + 12).to_s
        before_now_day = (before_now_day - 1).to_s
      end

      time = Time.now.strftime("%Y-%m-#{before_now_day}T#{before_now_hour}:#{Time.now.strftime('%M')}:%S.000Z").to_s
      request_names = if id.present?
                        "#{request_name}/#{id}?expand=*&"
                      else
                        "#{request_name}?filter=creationTime+gt+'#{time}'&expand=*&"
                      end
      Rails.logger.info "request_names#{request_names}"
      {
          source: @source,
          request_name: request_names
      }
    end



  end
end
