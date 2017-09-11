extend RollingRestart::Helpers

if elb_load_balancer?
  node.set[:app_restart][:elb_load_balancer] = elb_load_balancer if elb_load_balancer && !node[:app_restart][:elb_load_balancer]
  gem_package 'aws-sdk-core' do
    version '2.10'
  end

  cookbook_file "#{node[:app_restart][:bin_dir]}/elb_manager.rb" do
    source 'elb_manager.rb'
    mode '755'
  end
else
  node.set[:app_restart][:load_balancer_ip] = load_balancer[:private_ip] if load_balancer && !node[:app_restart][:load_balancer_ip]
end


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
