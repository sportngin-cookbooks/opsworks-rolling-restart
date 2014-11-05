
template "#{node[:rolling_restart][:base_dir]}/#{node[:rolling_restart][:remove_bin]}" do
  source node[:rolling_restart][:remove_template]
  cookbook node[:rolling_restart][:cookbook]
  variables(node[:app_restart])
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end

template "#{node[:app_restart][:base_dir]}/#{node[:app_restart][:add_bin]}" do
  source node[:app_restart][:add_template]
  cookbook node[:rolling_restart][:cookbook]
  variables(node[:app_restart])
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end

template "#{node[:app_restart][:base_dir]}/#{node[:app_restart][:restart_bin]}" do
  source node[:app_restart][:restart_template]
  cookbook node[:rolling_restart][:cookbook]
  variables(node[:app_restart])
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end

