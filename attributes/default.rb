default[:rolling_restart][:cookbook] = 'opsworks-rolling-restart'

default[:rolling_restart][:ssh][:user] = 'deploy'
default[:rolling_restart][:ssh][:group] = 'opsworks'

default[:rolling_restart][:restart_command] = 'rolling_restart'

default[:app_restart][:load_balancer][:ip] = load_balancer[:private_ip]
default[:app_restart][:load_balancer][:remove_command] = "ssh #{node[:rolling_restart][:ssh][:user]}@#{node[:rolling_restart][:load_balancer][:ip]} \"sudo sed -i -r 's/(.*server.*#{node[:local_ipv4}}.*)/#&/g' /etc/haproxy.cfg; sudo /etc/init.d/haproxy reload\""
default[:app_restart][:load_balancer][:add_command] = "ssh #{node[:rolling_restart][:ssh][:user]}@#{node[:rolling_restart][:load_balancer][:ip]} \"sudo sed -i -r 's/^#*(.*server.*#{node[:local_ipv4}}.*)/\1/g' /etc/haproxy.cfg; sudo /etc/init.d/haproxy reload\""

default[:app_restart][:base_dir] = '/usr/local/bin'

default[:app_restart][:add_bin] = 'haproxy-add'
default[:app_restart][:add_template] = 'haproxy-add.sh.erb'

default[:app_restart][:remove_bin] = 'haproxy-remove'
default[:app_restart][:remove_template] = 'haproxy-remove.sh.erb'

default[:app_restart][:restart_bin] = 'app-restart'
default[:app_restart][:restart_template] = 'app-restart.sh.erb'

default[:app_restart][:app_running_command] = 'curl --silent --fail --max-time 5 127.0.0.1:$PORT/okcomputer'
default[:app_restart][:finishe_requests_command] = 'sleep 10'
default[:app_restart][:app_port] = 81
default[:app_restart][:timeout] = 60
