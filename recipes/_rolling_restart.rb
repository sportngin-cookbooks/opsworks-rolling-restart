extend RollingRestart::Helpers
# Cookbook Name:: opsworks-rolling-restart
# Recipe:: default

user = node[:rolling_restart][:ssh][:user]
group = node[:rolling_restart][:ssh][:group]

instances = app_instances

template "#{node[:rolling_restart][:bin_dir]}/#{node[:rolling_restart][:bin]}" do
  source node[:rolling_restart][:template]
  cookbook node[:rolling_restart][:cookbook]
  owner user
  group group
  mode 0755
  action :create
  backup false
  variables(
    :before_restart_command => node[:rolling_restart][:before_command],
    :after_restart_command => node[:rolling_restart][:after_command],
    :app_restart_command => "#{node[:app_restart][:bin_dir]}/#{node[:app_restart][:restart_bin]}",
    :ip_addresses => instances.map{|hostname, data| data[:private_ip] },
    :user => user
  )
end
