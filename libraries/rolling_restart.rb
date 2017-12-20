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
        instances = node[:opsworks][:layers].map { |layer_name, layer_attrs| layer_attrs[:instances] if layer_name.to_s.include?("app") }
      else
        app_layer = search("aws_opsworks_layer").select{ |l| l[:shortname].include?("app") }.first
        layer_id = app_layer['layer_id']
        instances = search("aws_opsworks_instance").select{ |i| i[:layer_ids].include?(layer_id) }
      end

      make_hash(instances)
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

    def elb_load_balancer
      if chef_11?
        node[:opsworks][:stack][:'elb-load-balancers'].first
      else
        search("aws_opsworks_elastic_load_balancer").first
      end
    end

    def elb_load_balancer?
      node[:rolling_restart][:load_balancer_type] == 'elb'
    end
  end
end
