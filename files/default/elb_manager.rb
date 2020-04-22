#!/usr/local/bin/ruby

# Usage: elb_manager.rb <region_name> <elb_type> <elb_name> <instance_id> <register/deregister> <registration_timeout>

require 'aws-sdk-core'

class ELBManager
  def initialize
    @region_name = ARGV[0]
    @elb_type = ARGV[1]
    @elb_name = ARGV[2]
    @instance_id = ARGV[3]
    @cmd = ARGV[4]
    @timeout = ARGV[5] || 300
    timeout_at = Time.now + @timeout
    Thread.abort_on_exception
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

  private def deregister_instance
    begin
      case @elb_name.downcase
      when 'elb'
        client.deregister_instances_from_load_balancer(elb_instance_params)
        client.wait_until(:instance_deregistered, elb_instance_params) do |w|
          # disable max attempts
          w.max_attempts = nil

          w.before_attempt do |attempts|
            chef::log.info("waiting for #{@instance_id} to be deregistered (attempt #{attempts + 1})")
          end

          w.delay = 15
          w.before_wait do
            throw :failure if time.now > timeout_at
          end
        end
      when 'alb', 'nlb'
        threads = []
        elb_instance_params.each do |elb_instance_param|
          threads << Thread.new {
            client.deregister_targets(elb_instance_param)
            client.wait_until(:target_deregistered, elb_instance_param) do |w|
              # disable max attempts
              w.max_attempts = nil

              w.before_attempt do |attempts|
                chef::log.info("waiting for #{@instance_id} to be deregistered (attempt #{attempts + 1})")
              end

              w.delay = 15
              w.before_wait do
                throw :failure if time.now > timeout_at
              end
            end
          }
        end
        threads.each(&:join)
      end
    rescue Aws::Waiters::Errors::WaiterFailed
      raise "max # of attempts reached. deregistration of #{@instance_id} from #{@elb_name} failed."
    end
  end

  private def register_instance
    begin
      case @elb_name.downcase
      when 'elb'
        client.register_instances_with_load_balancer(elb_instance_params)
        client.wait_until(:instance_in_service, elb_instance_params) do |w|
          # disable max attempts
          w.max_attempts = nil

          w.before_attempt do |attempts|
            chef::log.info("waiting for #{@instance_id} to be in service (attempt #{attempts + 1})")
          end

          w.delay = 15
          w.before_wait do
            throw :failure if time.now > timeout_at
          end
        end
      when 'alb', 'nlb'
        threads = []
        elb_instance_params.each do |elb_instance_param|
          threads << Thread.new {
            client.deregister_targets(elb_instance_param)
            client.wait_until(:target_deregistered, elb_instance_param) do |w|
              # disable max attempts
              w.max_attempts = nil

              w.before_attempt do |attempts|
                chef::log.info("waiting for #{@instance_id} to in service (attempt #{attempts + 1})")
              end

              w.delay = 15
              w.before_wait do
                throw :failure if time.now > timeout_at
              end
            end
          }
        end
        threads.each(&:join)
      end
    rescue Aws::Waiters::Errors::WaiterFailed
      raise "max # of attempts reached. deregistration of #{@instance_id} from #{@elb_name} failed."
    end
  end

  private def target_group_hash(target_group, target)
    {
      target_group_arn: "#{target_group}",
      targets: [
        {
          id: "#{target}"
        }
      ]
    }
  end

  private def elb_instance_params
    case @elb_name.downcase
    when 'elb'
      @elb_instance_params ||= {
        load_balancer_name: @elb_name,
        instances: [{ instance_id: @instance_id }]
      }
    when 'nlb', 'alb'
      # An arr of target_group_hash structures
      if @elb_instance_params
        @elb_instance_params
      else
        resp = client.describe_target_groups(
          load_balancer_arn: @elb_name
        )
        @elb_instance_params = resp.target_groups.map do |tg| 
          target_group_hash(tg.target_group_arn, @instance_id)
        end
      end
    end
  end

  private def client
    case @elb_name.downcase
    when 'elb'
      @client ||= Aws::ElasticLoadBalancing::Client.new(region: @region_name)
    when 'nlb', 'alb'
      @client ||= Aws::ElasticLoadBalancingV2::Client.new(region: @region_name)
    else
      raise ArgumentError.new("Load balancer type must be one of [elb, alb, nlb]")
    end
  end

end

ELBManager.new.run

