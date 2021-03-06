extend RollingRestart::Helpers

if elb_load_balancer?
  node.set[:app_restart][:elb_load_balancer_name] = elb_load_balancer_name if elb_load_balancer_name && !node[:app_restart][:elb_load_balancer_name]

  gem_package 'aws-sdk-elasticloadbalancing' do
    version '1.20'
  end

  gem_package 'aws-sdk-elasticloadbalancingv2' do
    version '1.14'
  end

  cookbook_file "#{node[:app_restart][:bin_dir]}/elb_manager.rb" do
    source 'elb_manager.rb'
    mode '755'
  end
else
  node.set[:app_restart][:load_balancer_ip] = load_balancer[:private_ip] if load_balancer && !node[:app_restart][:load_balancer_ip]
end

region = get_instance_region

template "#{node[:app_restart][:bin_dir]}/#{node[:app_restart][:remove_bin]}" do
  source node[:app_restart][:remove_template]
  cookbook node[:app_restart][:remove_template_cookbook]
  variables(node: node[:app_restart], region: region)
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end

template "#{node[:app_restart][:bin_dir]}/#{node[:app_restart][:add_bin]}" do
  source node[:app_restart][:add_template]
  cookbook node[:app_restart][:add_template_cookbook]
  variables(node: node[:app_restart], region: region)
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end

template "#{node[:app_restart][:bin_dir]}/#{node[:app_restart][:restart_bin]}" do
  source node[:app_restart][:restart_template]
  cookbook node[:app_restart][:restart_template_cookbook]
  variables(node[:app_restart])
  mode '0755'
  user node[:rolling_restart][:user] || 'root'
  group node[:rolling_restart][:group] || 'root'
end
