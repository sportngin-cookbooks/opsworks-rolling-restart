# Cookbook Name:: opsworks-rolling-restart
# Recipe:: default

normal[:appname] = node[:opsworks][:applications].first["slug_name"]
public_key = node[node[:appname]][:deploy_pub_key]
instances = []
node[:opsworks][:layers].each do |layer, layer_attrs|
  if layer.to_s.include?("app")
    instances += layer_attrs[:instances].map {|instance, instance_attrs| instance_attrs[:private_ip]} ).compact 
  end
end

template "/usr/local/bin/rolling_restart.sh" do
  source "rolling_restart.sh.erb"
  owner node[:user]
  group node[:group]
  mode 0755
  action :create
  backup false
  variables :instances => instances.uniq,
end


file "/home/#{node[:user]}/.ssh/authorized_keys" do
  owner node[:user]
  group node[:group]
  mode 0700
  backup false
  content node[:public_key]
end

