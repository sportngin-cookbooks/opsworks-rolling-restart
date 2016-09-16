module RollingRestart
  module Helpers
    def app_instances
      node[:opsworks][:layers].map { |layer_name, layer_attrs|
        layer_attrs[:instances] if layer_name.to_s.include?("app")
      }.compact.flatten(1).reduce(&:merge) # Flatten down the list of instances to a hash of { hostname: instance_data }
    end

    def instances
      node[:opsworks][:layers].map { |layer_name, layer_attrs| layer_attrs[:instances] }.compact.flatten(1).reduce(&:merge)
    end

    def load_balancer
      instances.detect{|hostname, data|
        data[:elastic_ip] && !data[:elastic_ip].empty?
      }.last
    end

    def elb_load_balancer
      node[:opsworks][:stack][:'elb-load-balancers'].first
    end

    def elb_load_balancer?
      node[:rolling_restart][:load_balancer_type] == 'elb'
    end
  end
end
