module RollingRestart
  module Helpers
    def chef_11?
      node[:opsworks]
    end

    def app_instances
      if chef_11?
        node[:opsworks][:layers].map { |layer_name, layer_attrs|
          layer_attrs[:instances] if layer_name.to_s.include?("app")
        }.compact.flatten(1).reduce(&:merge) # Flatten down the list of instances to a hash of { hostname: instance_data }
      else
        app_layer = search("aws_opsworks_layer").select{ |l| l['shortname'].include?("app") }.first
        layer_id = app_layer['layer_id']
        instances = search("aws_opsworks_instance").select{ |i| i['layer_ids'].include?(layer_id) }.compact.flatten(1).reduce(&:merge)
      end
    end

    def instances
      if chef_11?
        node[:opsworks][:layers].map { |layer_name, layer_attrs| layer_attrs[:instances] }.compact.flatten(1).reduce(&:merge)
      else
        instances = search("aws_opsworks_instance")
      end
    end

    def load_balancer
      if chef_11?
        instances.detect{ |hostname, data|
          data[:elastic_ip] && !data[:elastic_ip].empty?
        }.last
      else
        instances.detect{ |hostname, data|
          data['elastic_ip'] != "null"
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
