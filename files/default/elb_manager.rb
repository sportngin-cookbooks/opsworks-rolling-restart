#!/usr/local/bin/ruby

# Usage: elb_manager.rb <region_name> <elb_type> <elb_name> <instance_id> <register/deregister> <registration_timeout>

require 'aws-sdk-core'
require 'aws-sdk-elasticloadbalancing'
require 'aws-sdk-elasticloadbalancingv2'

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
    instance_registrar(@cmd)
  end

  private

  def instance_registrar(task)
    registrar_params = {
      verb: task,
      function: nil,
      type: nil
    }
    # Build appropriate params for (de)registration
    case task.downcase
    when 'register'
      case @elb_name.downcase
      when 'elb'
        registrar_params[:function] = 'register_instances_with_load_balancer'
        registrar_params[:type] = 'instance'
      when 'alb', 'nlb'
        registrar_params[:function] = 'register_targets'
        registrar_params[:type] = 'target'
      end
    when 'deregister'
      case @elb_name.downcase
      when 'elb'
        registrar_params[:function] = 'deregister_instances_from_load_balancer'
        registrar_params[:type] = 'instance'
      when 'alb', 'nlb'
        registrar_params[:function] = 'deregister_targets'
        registrar_params[:type] = 'target'
      end
    else
      raise ArgumentError.new("Unsupported task type. Only the following tasks are supported: [register, deregister]")
    end

    begin
      threads = []
      elb_instance_params.each do |elb_instance_param|
        threads << Thread.new {
          # Build the following structure: client.deregister_targets(elb_instance_param)
          client.send registrar_params[:function].to_sym, elb_instance_param
          # Build the following structure: client.wait_until(:target_deregistered, elb_instance_param) do |w|
          client.wait_until("#{registrar_params[:type]}_#{task}".to_sym, elb_instance_param) do |w|
            # disable max attempts
            w.max_attempts = nil

            w.before_attempt do |attempts|
              chef::log.info("waiting for #{@instance_id} to be #{task}ed (attempt #{attempts + 1})")
            end

            w.delay = 15
            w.before_wait do
              throw :failure if time.now > timeout_at
            end
          end
        }
      end
      threads.each(&:join)
    rescue Aws::Waiters::Errors::WaiterFailed
      # Convert '(de)register' to a noun
      raise "max # of attempts reached. #{task[0...-2]}ration of #{@instance_id} from #{@elb_name} failed."
    end   
  end

  def target_group_hash(target_group, target)
    {
      target_group_arn: "#{target_group}",
      targets: [
        {
          id: "#{target}"
        }
      ]
    }
  end

  def elb_instance_params
    case @elb_type.downcase
    when 'elb'
      @elb_instance_params ||= [{
        load_balancer_name: @elb_name,
        instances: [{ instance_id: @instance_id }]
      }]
    when 'nlb', 'alb'
      # An arr of target_group_hash structures
      unless @elb_instance_params
        resp = client.describe_load_balancers(
          names: [@elb_name]
        )
        resp = client.describe_target_groups(
          load_balancer_arn: resp.load_balancers.first.load_balancer_arn
        )
        @elb_instance_params = resp.target_groups.map do |tg| 
          target_group_hash(tg.target_group_arn, @instance_id)
        end
      end
    end
    @elb_instance_params
  end

  def client
    case @elb_type.downcase
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

