extend RollingRestart::Helpers
# Cookbook Name:: opsworks-rolling-restart
# Recipe:: default

user = node[:rolling_restart][:ssh][:user]
group = node[:rolling_restart][:ssh][:group]

instances = app_instances

template "/usr/local/bin/rolling_restart" do
  source "rolling_restart.sh.erb"
  owner user
  group group
  mode 0755
  action :create
  backup false
  variables :ip_addresses => instances.map{|hostname, data| data[:private_ip] }
end
