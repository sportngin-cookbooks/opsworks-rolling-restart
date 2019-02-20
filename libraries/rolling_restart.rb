module RollingRestart
  module Helpers
    def chef_11?
      node[:opsworks]
    end

    # Returns instance data as a hash of instances where the instance hostname is the key, and a hash of data is the value:
    #   { hostname1: { key1: value, key2: value },
    #     hostname2: { key1: value, key2: value },
    #     hostname3: { key1: value, key2: value },
    #   }
    def make_hash(instances)
      if chef_11?
        instances.compact.flatten(1).reduce(&:merge)
      else
        instances_hash = {}

        instances.each do |instance|
          instances_hash["#{instance[:hostname]}"] = instance
        end

        instances_hash
      end
    end

    def app_instances
      if chef_11?
        instances = app_layers_chef_11.map{ |layer, attrs| instances_for_layer(attrs) }.inject(&:merge)
      else
        app_layer = app_layers.first
        layer_id = app_layer[:layer_id]
        instances = search("aws_opsworks_instance").select{ |i| (i[:layer_ids].include?(layer_id)) && (i[:status] == "online") }
      end

      make_hash(instances)
    end

    def opsworks_layer_include_override
      node[:rolling_restart][:opsworks_layer_include_override] || []
    end

    def app_layers_chef_11
      layers = node[:opsworks][:layers]
      return layers.select{|layer, attrs| layer.to_s.include?("app") } if opsworks_layer_include_override.empty?
      layers.select{|layer, attrs| opsworks_layer_include_override.include?(layer.to_s) }
    end

    def app_layers
      layers = search("aws_opsworks_layer")
      return layers.select{ |l| l[:shortname].include?("app") }.first if opsworks_layer_include_override.empty?
      layers.select{|l| opsworks_layer_include_override.include?(l[:shortname]) }
    end

    def get_instances
      if chef_11?
        instances = node[:opsworks][:layers].map { |layer_name, layer_attrs| layer_attrs[:instances] }
      else
        instances = search("aws_opsworks_instance")
      end

      make_hash(instances)
    end

    def load_balancer
      if chef_11?
        get_instances.detect{ |hostname, data|
          data[:elastic_ip] && !data[:elastic_ip].empty?
        }.last
      else
        get_instances.detect{ |hostname, data|
          data[:elastic_ip] != "null"
        }.last
      end
    end

    def elb_load_balancer_name
      if chef_11?
        node[:opsworks][:stack][:'elb-load-balancers'].first[:name]
      else
        search("aws_opsworks_elastic_load_balancer").first[:elastic_load_balancer_name]
      end
    end

    def elb_load_balancer?
      node[:rolling_restart][:load_balancer_type] == 'elb'
    end

    def get_instance_region
      if chef_11?
        node[:opsworks][:instance][:region]
      else
        search("aws_opsworks_instance", "self:true").first[:availability_zone].chop
      end
    end
  end
end
