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
    @task = ARGV[4]
    @timeout = ARGV[5] || 300
    @timeout_at = Time.now + @timeout
    Thread.abort_on_exception

    case @task.downcase
    when 'register'
      @waiter_name_suffix = "in_service"
    when 'deregister'
      @waiter_name_suffix = "#{@task}ed"
    else
      raise ArgumentError.new("Unsupported @task type. Only the following tasks are supported: [register, deregister]")
    end
  end

  def run
    instance_registrar
  end

  private

  ##
  # (De)registers the instance from the ELB or target groups of the A/NLB
  def instance_registrar
    case @elb_type.downcase
    when 'elb'
      elb_registrar
    when 'alb', 'nlb'
      elbv2_registrar
    end
  end

  def elb_registrar
    begin
      # Build the following structure: client.deregister_instances_with_load_balancer(elb_instance_params)
      client.send "#{@task}_instances_with_load_balancer".to_sym, elb_instance_params
      # Build the following structure: client.wait_until(:instance_deregistered, elb_instance_params) do |w|
      client.wait_until("instance_#{@waiter_name_suffix}".to_sym, elb_instance_params) do |w|
        # disable max attempts
        w.max_attempts = nil

        w.before_attempt do |attempts|
          chef::log.info("#{@elb_type} #{@elb_name}: waiting for #{@instance_id} to be #{@task}ed (attempt #{attempts + 1})")
        end

        w.delay = 15
        w.before_wait do
          throw :failure if Time.now > @timeout_at
        end
      end
    rescue Aws::Waiters::Errors::WaiterFailed
      # Convert '(de)register' to a noun
      raise "max # of attempts reached. #{@task[0...-2]}ration of #{@instance_id} from #{@elb_name} failed."
    end
  end

  def elbv2_registrar
    begin
      threads = []
      elb_instance_params.each do |elb_instance_param|
        threads << Thread.new {
          # Build the following structure: client.deregister_targets(elb_instance_param)
          client.send "#{@task}_targets".to_sym, elb_instance_param
          # Build the following structure: client.wait_until(:target_deregistered, elb_instance_param) do |w|
          client.wait_until("target_#{@waiter_name_suffix}".to_sym, elb_instance_param) do |w|
            # disable max attempts
            w.max_attempts = nil

            w.before_attempt do |attempts|
              chef::log.info("#{@elb_type} #{@elb_name}: waiting for #{@instance_id} to be #{@task}ed (attempt #{attempts + 1})")
            end

            w.delay = 15
            w.before_wait do
              throw :failure if Time.now > @timeout_at
            end
          end
        }
      end
      threads.each(&:join)
    rescue Aws::Waiters::Errors::WaiterFailed
      # Convert '(de)register' to a noun
      raise "max # of attempts reached. #{@task[0...-2]}ration of #{@instance_id} from #{@elb_name} failed."
    end   
  end

  ##
  # Returns an arr of hash structures for alb/nlb, or a hash structure for elb.
  # The structure is meant to be ingested by AWS SDK functions.
  def elb_instance_params
    unless @elb_instance_params
      case @elb_type.downcase
      when 'elb'
        elb_sdk_param_builder
      when 'alb', 'nlb'
        elbv2_sdk_param_builder
      end
    end

    @elb_instance_params
  end

  def elb_sdk_param_builder
    @elb_instance_params ||= {
      load_balancer_name: @elb_name,
      instances: [{ instance_id: @instance_id }]
    }
  end

  def elbv2_sdk_param_builder
    # An arr of target_group_hash structures
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

  ##
  # Hash template used for `elb_instance_params` when using A/NLB
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

  ##
  # Returns an ELB client object
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

