default[:rolling_restart][:cookbook] = 'opsworks-rolling-restart'

default[:rolling_restart][:ssh][:user] = 'deploy'
default[:rolling_restart][:ssh][:group] = 'opsworks'

default[:rolling_restart][:bin_dir] = '/usr/local/bin'
default[:rolling_restart][:template] = 'rolling-restart.sh.erb'
default[:rolling_restart][:bin] = 'rolling-restart'
default[:rolling_restart][:timeout] = 1800
default[:rolling_restart][:load_balancer_type] = 'haproxy'

default[:app_restart][:load_balancer_ip] = nil
default[:app_restart][:elb_load_balancer_name] = nil

default[:app_restart][:bin_dir] = '/usr/local/bin'

default[:app_restart][:add_bin] = 'haproxy-add'
default[:app_restart][:add_template] = 'haproxy-add.sh.erb'
default[:app_restart][:add_template_cookbook] = 'opsworks-rolling-restart'

default[:app_restart][:remove_bin] = 'haproxy-remove'
default[:app_restart][:remove_template] = 'haproxy-remove.sh.erb'
default[:app_restart][:remove_template_cookbook] = 'opsworks-rolling-restart'

default[:app_restart][:restart_bin] = 'app-restart'
default[:app_restart][:restart_template] = 'app-restart.sh.erb'
default[:app_restart][:restart_template_cookbook] = 'opsworks-rolling-restart'

default[:app_restart][:app_running_command] = 'curl --silent --fail --max-time 5 127.0.0.1:$PORT/okcomputer'
default[:app_restart][:finished_requests_command] = 'sleep 10'
default[:app_restart][:app_port] = 81
default[:app_restart][:retries] = 10
