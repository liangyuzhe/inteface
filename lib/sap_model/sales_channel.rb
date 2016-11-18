#encoding: utf-8

module SapModel

  class SalesChannel
    #
    # 获取sap所有渠道信息中云店家的sap_id
    # @note 获取sap所有渠道信息中云店家的sap_id
    # @param source [string]
    def self.get_sales_channels(source)
      Rails.logger.info "source为#{source}"
      sales_channels = Sap::SalesChannel.new(source).list
      sap_id = nil
      if sales_channels.present?
        sales_channels.each do |sale_channel|
          if sale_channel.try('name') == '云店家' && sale_channel.try('status')  == 'ACTIVE'
           sap_id = sale_channel.id
         end
       end
      end
      return sap_id
    end

    # 获取sap上云店家所有上架商品的信息
    # @note 获取sap上云店家所有上架商品的信息
    # @param source [string]
    def self.get_sku_yun(source)
      sap_id = self.get_sales_channels(source)
      on_shelf_products = Sap::SalesChannel.new(source).find_sku(sap_id)
    end

    # 更新sap商品上架的信息(sap某个商品规格全部下架时yundianjia才下架)
    # @note 更新sap商品上架的信息(sap某个商品规格全部下架时yundianjia才下架)
    # @param source [string]
    def self.update_products_status(source, shop_id)
      on_shelf_product_map = self.get_sku_yun(source).each_with_object({})  do |on_shelf_product, map|
        key = on_shelf_product.try(:code).split('-').first
        if map[key].blank?
          map[key] = 1
        else
          map[key] += 1
        end
      end
      on_shelf_product_art_codes = on_shelf_product_map.keys
      Rails.logger.info "on_shelf_product_codes#{on_shelf_product_art_codes}"
      sap_product_art_codes = ::Product.where(source: source).map(&:art_no)
      off_shelf_product_art_codes = sap_product_art_codes - on_shelf_product_art_codes
      on_shelf_product_art_codes.each do |key|
        self.update_yun_product_status(key, ::Product::Status::Published, source, shop_id)
      end
      off_shelf_product_art_codes.each do |key|
        self.update_yun_product_status(key, ::Product::Status::Closed, source, shop_id)
      end
    end

    # 更新sap商品上架的信息(sap某个商品规格全部下架时yundianjia才下架)的子方法
    # @note 更新sap商品上架的信息(sap某个商品规格全部下架时yundianjia才下架)的子方法
    # @param source [string]
    def self.update_yun_product_status(key, status, source, shop_id)
      sap_product = ::Product.where(source: source, art_no: key, shop_id: shop_id).last
      sap_product.status = status
      sap_product.save!
    rescue => e
      yloge e, "更新' 商品状态 商品art_code #{key}, 失败"
    end
  end
end