# Cookbook Name:: opsworks-rolling-restart
# Recipe:: default

user = node[:rolling_restart][:ssh][:user]
group = node[:rolling_restart][:ssh][:group]

instances = []
node[:opsworks][:layers].each do |layer, layer_attrs|
  if layer.to_s.include?("app")
    instances += layer_attrs[:instances].map{|instance, instance_attrs| instance_attrs[:private_ip]}.compact 
  end
end

template "/usr/local/bin/rolling_restart" do
  source "rolling_restart.erb"
  owner user
  group group
  mode 0755
  action :create
  backup false
  variables :instances => instances.uniq
end