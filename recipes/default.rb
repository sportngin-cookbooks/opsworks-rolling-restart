# Cookbook Name:: opsworks-rolling-restart
# Recipe:: default

user = node[:rolling_restart][:ssh][:user]
public_key = node[:rolling_restart][:ssh][:public_key]

instances = []
node[:opsworks][:layers].each do |layer, layer_attrs|
  if layer.to_s.include?("app")
    instances += layer_attrs[:instances].map {|instance, instance_attrs| instance_attrs[:private_ip]} ).compact 
  end
end

template "/usr/local/bin/rolling_restart.sh" do
  source "rolling_restart.sh.erb"
  owner user
  group node[:group]
  mode 0755
  action :create
  backup false
  variables :instances => instances.uniq,
end


file "/home/#{user}/.ssh/authorized_keys" do
  owner user
  group node[:group]
  mode 0700
  backup false
  content public_key
end if public_key

