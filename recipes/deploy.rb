ruby_block "Rolling Restart" do
  block do
    cmd = Mixlib::ShellOut.new("#{node[:rolling_restart][:bin_dir]}/#{node[:rolling_restart][:bin]}", :timeout => node[:rolling_restart][:timeout])
    cmd.run_command
    Chef::Log.info([cmd.stderr, cmd.stdout].join("\n"))
    cmd.error!
  end
end
