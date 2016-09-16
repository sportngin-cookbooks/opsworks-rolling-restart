#!/usr/local/bin/ruby

# Usage: elb_manager.rb <region_name> <elb_name> <instance_id> <register/deregister>

require 'aws-sdk-core'

class ELBManager
  def initialize
    @region_name = ARGV[0]
    @elb_name = ARGV[1]
    @instance_id = ARGV[2]
    @cmd = ARGV[3]
  end

  def run
    case @cmd
      when 'register'
        register_instance
      when 'deregister'
        deregister_instance
      else
        puts "Unable to parse command #{@cmd}"
    end
  end

  private
  def deregister_instance
    client.deregister_instances_from_load_balancer(elb_instance_params)
  end

  private
  def register_instance
    client.register_instances_with_load_balancer(elb_instance_params)
  end

  private
  def elb_instance_params
    {
      load_balancer_name: @elb_name,
      instances: [{ instance_id: @instance_id }]
    }
  end

  private
  def client
    @client ||= Aws::ElasticLoadBalancing::Client.new(region: @region_name)
  end

end

ELBManager.new.run

