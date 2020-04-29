#!/usr/local/bin/ruby

# Usage: elb_manager.rb -r <region_name> -t <elb_type> -n <elb_name> -i <instance_id> -k <register/deregister> -o <registration_timeout>

require 'optparse'
require 'aws-sdk-core'
require 'aws-sdk-elasticloadbalancing'
require 'aws-sdk-elasticloadbalancingv2'

class ELBManager
  def initialize
    parse
    @options[:timeout] ||= 300
    @timeout_at = Time.now + @options[:timeout]
    Thread.abort_on_exception

    unless @options[:task].downcase.match /^(de)?register$/
      raise ArgumentError.new("Unsupported task. Only the following tasks are supported: [register, deregister]")
    end

    unless @options[:elb_type].downcase.match /^[aen]lb$/
      raise ArgumentError.new("Load balancer type must be one of [elb, alb, nlb]")
    end
  end

  def run
    instance_registrar
  end

  private

  ##
  # (De)registers the instance from the ELB or target groups of the A/NLB
  def instance_registrar
    case @options[:elb_type].downcase
    when 'elb'
      elb_registrar
    when 'alb', 'nlb'
      elbv2_registrar
    end
  end

  def elb_registrar
    case @options[:task].downcase
    when 'register'
      waiter_name = 'instance_in_service'
      client.register_instances_with_load_balancer(elb_instance_params)
    when 'deregister'
      waiter_name = 'instance_deregistered'
      client.deregister_instances_from_load_balancer(elb_instance_params)
    end

    wait_for_lb_action(waiter_name, elb_instance_params)
  end

  def elbv2_registrar
    case @options[:task].downcase
    when 'register'
      task_method_name = 'register_targets'
      waiter_name = 'target_in_service'
    when 'deregister'
      task_method_name = 'deregister_targets'
      waiter_name = 'target_deregistered'
    end

    threads = []
    # Each target group operation has its own thread
    elb_instance_params.each do |elb_instance_param|
      threads << Thread.new {
        # Build the following structure: client.deregister_targets(elb_instance_param)
        client.send task_method_name.to_sym, elb_instance_param
        wait_for_lb_action(waiter_name, elb_instance_param)
      }
    end
    threads.each(&:join)
  end

  ##
  # Wait until the specified elb or elbv2 action completes. Check AWS SDK ELB and ELBv2 for supported
  # waiters and param types.
  #   waiter - String
  #   param - Hash
  # ELB SDK: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/ElasticLoadBalancing/Waiters.html
  # ELBv2 SDK: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/ElasticLoadBalancingV2/Waiters.html
  def wait_for_lb_action(waiter, param)
    begin
      # i.e. client.wait_until(:target_deregistered, elb_instance_param) do |w|
      client.wait_until(waiter.to_sym, param) do |w|
        # disable max attempts
        w.max_attempts = nil

        w.before_attempt do |attempts|
          chef::log.info("#{@options[:elb_type].upcase} #{@options[:elb_name]}: waiting for #{@options[:instance_id]} to be #{@options[:task]}ed (attempt #{attempts + 1})")
        end

        w.delay = 15
        w.before_wait do
          throw :failure if Time.now > @timeout_at
        end
      end
    rescue Aws::Waiters::Errors::WaiterFailed
      # Convert '(de)register' to a noun
      raise "max # of attempts reached. #{@options[:task][0...-2]}ration of #{@options[:instance_id]} from #{@options[:elb_name]} failed."
    end   
  end

  ##
  # Returns an arr of hash structures for alb/nlb, or a hash structure for elb.
  # The structure is meant to be ingested by AWS SDK functions.
  def elb_instance_params
    unless @elb_instance_params
      case @options[:elb_type].downcase
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
      load_balancer_name: @options[:elb_name],
      instances: [{ instance_id: @options[:instance_id] }]
    }
  end

  def elbv2_sdk_param_builder
    # An arr of target_group_hash structures
    resp = client.describe_load_balancers(
      names: [@options[:elb_name]]
    )
    resp = client.describe_target_groups(
      load_balancer_arn: resp.load_balancers.first.load_balancer_arn
    )
    @elb_instance_params = resp.target_groups.map do |tg|
      target_group_hash(tg.target_group_arn, @options[:instance_id])
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
    case @options[:elb_type].downcase
    when 'elb'
      @client ||= Aws::ElasticLoadBalancing::Client.new(region: @options[:region])
    when 'nlb', 'alb'
      @client ||= Aws::ElasticLoadBalancingV2::Client.new(region: @options[:region])
    end
  end

  def parse
    @options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: elb_manager.rb [options]"

      opts.on("-r", "--region AWS_REGION", "AWS region name where the load balancer and instance live") do |r|
        @options[:region] = r
      end
      opts.on("-t", "--type ELB_TYPE", "Type of elastic load balancer. Should be one of `elb`, `alb`, or `nlb`") do |t|
        @options[:elb_type] = t
      end
      opts.on("-n", "--name ELB_NAME", "Name of load balancer. DO NOT provider ARN") do |n|
        @options[:elb_name] = n
      end
      opts.on("-i", "--instance-id EC2_INSTANCE_ID", "EC2 instance id") do |i|
        @options[:instance_id] = i
      end
      opts.on("-k", "--task TASK", "Desirable action. `register` or `deregister`") do |k|
        @options[:task] = k
      end
      opts.on("-o", "--timeout SECONDS", OptionParser::DecimalInteger, "Instance (de)registeration timeout") do |o|
        @options[:timeout] = o
      end
      opts.on("-h", "--help", "Help message") do
        puts opts
        exit
      end
    end.parse!
  end
end

ELBManager.new.run

