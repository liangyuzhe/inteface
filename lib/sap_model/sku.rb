#encoding: utf-8

module SapModel

  class Sku
    #
    # 根据来源获得所有商品规格
    # @note 根据来源获得所有商品规格
    # @param source [string]
    def self.get_skus(source)
      Sap::Sku.new(source).list
    end

    #
    # 根据来源获得所有商品规格variantvalue
    # @note 根据来源获得所有商品规格variantvalue
    # @param source [string]
    def self.get_variantvalues(source)
      Sap::VariantValue.new(source).list
    end

    #
    # 根据来源获得所有商品价格
    # @note 根据来源获得商品价格
    # @param source [string]
    def self.get_salespricelists(source)
      Sap::SalesPriceList.new(source).list
    end

    # 根据来源,id获得单个商品variantvalue
    # @note 根据来源,id获得单个商品variantvalue
    # @param source [string]
    def self.find_variantvalue(source, id)

      Sap::VariantValue.new(source).find(id)
    end

    # 根据来源,id获得单个商品
    # @note 根据来源,id获得单个商品
    # @param source [string]
    def self.find_salespricelists_sku(source, id, skuid)
      params = {skuid: skuid}
      Sap::SalesPriceList.new(source).find(id, params)
    end

    # 根据来源,id获得单个商品规格
    # @note 根据来源,id获得单个商品规格
    # @param source [string]
    def self.find_sku(source, id)
      Sap::Sku.new(source).find(id)
    end

    # 根据来源,id获得单个商品库存
    # @note 根据来源,id获得单个商品库存
    # @param source [string]
    def self.find_sku_warehouseinfo(source, id)
      params = {
          warehouseinfo: 'WarehouseInfos'
      }
      Sap::Sku.new(source).find(id, params)
    end

    # 根据来源,id获得单个商品
    # @note 根据来源,id获得单个商品
    # @param source [string]
    def self.find_sku_channelprice(source, id)
      params = {
          warehouseinfo: 'getChannelPrices'
      }
      Sap::Sku.new(source).find(id, params)
    end

    # 根据来源,id获得单个商品售价
    # @note 根据来源,id获得单个商品售价
    # @param source [string]
    def self.find_sku_standprice(source, id)
      params = {
          warehouseinfo: 'StandardPrice'
      }
      Sap::Sku.new(source).find(id, params)
    end

    # 为从sap接口获得的商品保存在云店家分装参数
    # @note 为从sap接口获得的商品保存在云店家分装参数
    # @param sap_product [sap_product]
    def self.query(sku, source)

     # if sku.try(:status) == 'Active'
     #   status = ::ProductVariant::Status::Published
     # else
     #   status = ::ProductVariant::Status::Closed
     # end

     sku_warehouseinfos = SapModel::Sku.find_sku_warehouseinfo(source, sku.id)
     inStocks = sku_warehouseinfos.warehouseInfoList.map(&:inStock).sum

     sku_standprice = SapModel::Sku.find_sku_standprice(source, sku.id).first

     price = sku_standprice.try(:price).present? ? sku_standprice.try(:price):0
     options = {
         # sku_code: sku.try(:code),
         inventory_quantity: inStocks,
         price: price,
         cost_price: sku.try(:grossPurchasePrice).present? ? sku.try(:grossPurchasePrice):0,
         market_price: price,
         art_no: sku.try(:code),
         weight: sku.try(:weight)
     }

     variantvalues = sku.try(:relatedVariantValues)
     if variantvalues.present?
       variantvalue_ids = variantvalues.map(&:id).first 3
     end


     if variantvalue_ids.present?
       variantvalue_ids.each_with_index  do |variantvalue_id, i|
        variantvalue = SapModel::Sku.find_variantvalue(source, variantvalue_id)
        key = variantvalue.try(:variant).try(:name)
        value = variantvalue.try(:value)
        options.merge!({"key#{i + 1}".to_sym => key, "value#{i + 1}".to_sym =>  value})
       end

     end

     Rails.logger.info "variantvalue.........#{options}"
     return options
    end



  end
end