#encoding: utf-8

module SapModel

  class Product
    #
    # 根据来源获得所有商品
    # @note 根据来源获得所有商品
    # @param source [string]
    def self.get_products(source)
      Sap::Product.new(source).list
    end


    # 根据来源,id获得单个商品
    # @note 根据来源,id获得单个商品
    # @param source [string]
    def self.find_product(source, id)
      Sap::Product.new(source).find(id)
    end

    def self.post_disableVariant(source, id)
      Sap::Product.new(source).posts(id)

    end

    # 根据来源,id获得单个商品图片
    # @note 根据来源,id获得单个商品图片
    # @param source [string]
    def self.find_product_attachment(source, id, attachment_id)
      Sap::Product.new(source).find_attachment(id, attachment_id)
    end

    # 为从sap接口获得的商品和商品规格保存在云店家分装参数
    # @note 为从sap接口获得的商品和商品规格保存在云店家分装参数
    # @param sap_product [sap_product]
    def self.query(product, source, shop_id)
      # if product.try(:status) == 'Active'
      #   status = ::Product::Status::Published
      # else
      #   status = ::Product::Status::Closed
      # end
      # shop_id = Shop.where(source: source, shop_type: Shop::ShopType::SHOP, status: Shop::Status::Open).last.id

      {
          art_no: product.try(:code),
          name: product.try(:name),
          product_type: product.try(:product_type),
          usefor: ProductDetail::Usefor::Product_Intro,
          source: source,
          shop_id: shop_id,
          settling_accounts_type: ::Product::SettlingAccountsType::CASH_AND_POINT,
          act_id: '0'   #sap商品先设为包邮的

      }

    end

    # 根据来源从sap接口获得的商品和商品规格保存在云店家
    # @note 根据来源从sap接口获得的商品和商品规格保存在云店家
    # @param source [string]
    # @param id [Integer]
    def self.new_or_update_product_by_source_and_id(source, id, shop_id)
      product = Sap::Product.new(source).find(id)
      Rails.logger.info "#{product}...product"
      if product.kind_of? Hash
      # products.each do |product|
        params = self.query(product, source, shop_id)
        sku_ids = product.try(:skus).map(&:id)
        specification = []
        total_inventory_quantity = 0
        if sku_ids.present?
          sku_ids.each do |id|
            sku = SapModel::Sku.find_sku(source, id)
            options = SapModel::Sku.query(sku, source)
            specification = specification<<options
            total_inventory_quantity += options[:inventory_quantity]
            Rails.logger.info "........specification: #{specification}......"
            Rails.logger.info "total_inventory_quantity...........#{total_inventory_quantity}"

          end
        end
        Rails.logger.info "paramsaaa...........#{params}"
        params.merge!(total_inventory_quantity: total_inventory_quantity)
        Rails.logger.info "paramsbbb...........#{params}"
        self.new_or_update_product(source, product, params, specification)
      # end
      end
    rescue => e
      yloge e, "更新' 商品失败 "
    end

    # 根据来源从sap接口获得的所有商品保存在云店家
    # @note 根据来源从sap接口获得的所有商品保存在云店家
    # @param source [string]
    def self.new_or_update_all_products_by_source(source, shop_id)
      products = Sap::Product.new(source).list
      products.each do |product|
        params = self.query(product, source, shop_id)
        sku_ids = product.try(:skus).map(&:id)
        specification = []
        if sku_ids.present?
          sku_ids.each do |id|
            sku = SapModel::Sku.find_sku(source,id)
            options = SapModel::Sku.query(sku, source)
            specification = specification<<options
            Rails.logger.info "........specification: #{specification}......"

          end

        end
        self.new_or_update_product(source, product, params, specification)
      end
    end

    # 根据来源从sap接口获得的商品保存在云店家(子方法)
    # @note 根据来源从sap接口获得的商品保存在云店家(子方法)
    # @param source [string]
    # @param sap_product [sap_product]
    def self.new_or_update_product(source, product, params, specification)
      yun_product = ::Product.where(art_no: product.try(:code)).last
      # product_category_grade_1 = ProductCategory.where(source: source, grade: ProductCategory::Grade::THREE).last.try(:id)
      category_name = product.try(:category).try(:name)
      category = ProductCategory.where(source: source, name: category_name).last
      default_category = ProductCategory.where(source: source, grade: ProductCategory::Grade::ONE).last
      product_category1_id = default_category.try(:id)
      product_category2_id = nil
      product_category_id = nil
      if category.present?
        grade = category.try(:grade)
        if grade == ProductCategory::Grade::ONE
          product_category1_id = category.try(:id)
        elsif grade == ProductCategory::Grade::TWO
          product_category2_id = category.try(:id)
          product_category1_id = category.parent.try(:id)
        elsif grade == ProductCategory::Grade::THREE
          product_category_id = category.try(:id)
          product_category2_id = category.parent.try(:id)
          product_category1_id = category.parent.parent.try(:id)

        end
      end
      Rails.logger.info "#product_category1_id#{product_category1_id}"
      # Rails.logger.info "#product_category2_id#{product_category2_id}"
      # Rails.logger.info "#product_category_id#{product_category_id}"

      options = {
          product_category_grade_1: product_category1_id
      }
      if product_category2_id.present?
        options.merge!(product_category_grade_2: product_category2_id)
      end
      if product_category_id.present?
        options.merge!(product_category_grade_3: product_category_id)
      end


      if yun_product.present?
        params = {product: params, specification: specification, id: yun_product.id}
        is_sap_product = true
        ::Product.update_product_for_fesco(params, options, is_sap_product)
        yun_product.total_inventory_quantity = yun_product.try(:product_variants).map{|p| p.inventory_quantity}.sum
        yun_product.save!
        Rails.logger.info ".....update_sap_product........."
      else
        result, product =::Product.add_product_for_fesco(params, options, specification)
        product.total_inventory_quantity = product.try(:product_variants).map{|p| p.inventory_quantity}.sum
        product.save!
        Rails.logger.info ".....add_sap_product........."
        ::Product.create!(options)
      end
    rescue => e
      yloge e, "更新' 商品code #{product.try(:code)},art_no#{product.try(:art_no)}, 失败"
    end

    # 根据来源从sap接口获得的商品保存与更新在云店家和上下架信息(定时任务)
    # @note 根据来源从sap接口获得的商品保存与更新在云店家和上下架信(定时任务)
    def self.new_or_update_all_product_info
      shop_ids_map = Sap::Product.new('').check_function_and_shop
      shop_ids_map.keys.each do |k|
        shop_ids = shop_ids_map[k].each do |shop_id|
          Rails.logger.info "new_or_update_all_product_info.....来源#{k}定时任务开始"
          self.new_or_update_all_products_by_source(k, shop_id)
          SapModel::SalesChannel.update_products_status(k, shop_id)
          Rails.logger.info "new_or_update_all_product_info.....来源#{k}定时任务结束"
        end
      end
    end
  end
end