#encoding: utf-8

module SapModel

  class User

    #
    # 根据来源获得所有发票
    # @note 根据来源获得所有发票
    # @param source [string]
    def self.get_users(source)
      Sap::User.new(source).list
    end


    # 根据来源,id获得单个发票
    # @note 根据来源,id获得单个发票
    # @param source [string]
    def self.find_customer(source, id)
      Sap::User.new(source).find(id)
    end

  end

end
