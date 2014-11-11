ruby_block "Rolling Restart" do
  block do
    cmd = Mixlib::ShellOut.new("#{node[:rolling_restart][:bin_dir]}/#{node[:rolling_restart][:bin]}")
    cmd.run_command
    cmd.error!
    [cmd.stderr, cmd.stdout].join("\n")
  end
end
