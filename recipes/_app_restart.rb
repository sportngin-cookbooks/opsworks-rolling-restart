extend RollingRestart::Helpers

node.set[:app_restart][:load_balancer_ip] = load_balancer[:private_ip] if load_balancer && !node[:app_restart][:load_balancer_ip]

template "#{node[:app_restart][:bin_dir]}/#{node[:app_restart][:remove_bin]}" do
  source node[:app_restart][:remove_template]
  cookbook node[:rolling_restart][:cookbook]
  variables(node[:app_restart])
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end

template "#{node[:app_restart][:bin_dir]}/#{node[:app_restart][:add_bin]}" do
  source node[:app_restart][:add_template]
  cookbook node[:rolling_restart][:cookbook]
  variables(node[:app_restart])
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end

template "#{node[:app_restart][:bin_dir]}/#{node[:app_restart][:restart_bin]}" do
  source node[:app_restart][:restart_template]
  cookbook node[:rolling_restart][:cookbook]
  variables(node[:app_restart])
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end

