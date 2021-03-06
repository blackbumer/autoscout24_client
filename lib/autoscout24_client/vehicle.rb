

module Autoscout24Client

  class Vehicle

    # all authorization logic
    include Authorization

    # all dictionaries
    include Dictionaries

    # main module for fetching vehicles using REST
    # find method
    include Finder

    # raw hash from autoscout24
    attr_accessor :source

    def initialize(node={})
      @source = node
    end

    # @return [String] model name like C220, A4, Pajero and etc
    def name
      brand_node = self.class.make_model_tree.find{|node| node["id"] == source["brand_id"].to_s}
      text_by_value(source["model_id"].to_s,brand_node)
    end

    ## @return [String] name of gear_type
    def gear_type
      @gear_type ||= generic_finder :gear_types, "gear_type_id"
    end

    ## @return [String] name of brand
    def brand
      @brand ||= generic_finder :brands, "brand_id"
    end

    ## @return [String] name of fuel_type
    def fuel
      @fuel ||= generic_finder :fuels, "fuel_type_id"
    end

    def method_missing(meth, *args, &block)
#    def method_missing(meth)
      keys = meth.id2name.split("__")
      keys.count>1 ? nested_hash_values(keys).compact : nested_hash_value(keys[0])
    end

    # Vat Rate by country of location
    # only D, I, B NL checked
    # TODO: discover other country codes by autoscout24
    # @return [Integer] VAT rate in % for country
    def vat_rate
      return 0 unless vat_type_id == "True"
      case country.downcase
        when *%w(hr); 27 #Hungary
        when *%w(s); 25 #Sweden
        when *%w(ro); 24 # Romania
        when *%w(el ie pl pt fi); 23  # .. .. Poland
        when *%w(b i lv lt); 21 # Belgium Italy Latvia Litva
        when *%w(bg cz ee a si sk uk slo ua); 20 #Slovakia  Slovenia Ukraine
        when *%w(d nl f); 19  #Germay Netherlands France
        when *%w(e mt cy rus tr); 18 # Spain .. .. Russia
        when *%w(l); 15 #Luxemburg
        when *%w(ch); 8 #Switzerland

        else 0
      end
    end

    # Netto public price in EUR for vehicle
    # @return [Integer] netto price
    def netto
      f_netto = value * 100 / (100 + vat_rate)
      f_netto.round
    end

    private

    #  hash helpers

    def generic_finder(collection, primary_key)
      self.class.send(collection).each do |object|
        return object["text"] if object["id"].to_s == source[primary_key].to_s
      end if source[primary_key]
      nil
    end

    def nested_hash_value(key, obj = source)
      if obj.respond_to?(:key?) && obj.key?(key)
        obj[key]
      elsif obj.respond_to?(:each)
        r = nil
        obj.find{ |*a| r=nested_hash_value(key, a.last) }
        r
      end
    end

    def nested_hash_values(keys, obj = source)
      normalized_keys = keys.kind_of?(String) ? keys.split(",") :keys
      normalized_keys.map{|k| nested_hash_value(k,obj)}
    end


    def text_by_value(value, obj)
      if obj.respond_to?(:key?) && obj.key?("id") && obj["id"] == value
        obj["text"]
      elsif obj.respond_to?(:each)
        r = nil
        obj.find{ |*a| r=text_by_value(value, a.last) }
        r
      end
    end


  end
end
