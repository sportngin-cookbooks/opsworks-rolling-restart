user = node[:rolling_restart][:ssh][:user]
group = node[:rolling_restart][:ssh][:group]
public_key = node[:rolling_restart][:ssh][:public_key]

home_dir = "/home/#{user}"

user user do
  home home_dir
  system true
end

group group do
  members user
end

directory home_dir do
  owner user
  group group
  mode 0700
end

directory "#{home_dir}/.ssh" do
  owner user
  group group
  mode 0700
end

authorized_keys_file = "#{home_dir}/.ssh/authorized_keys"
if File.size?(authorized_keys_file)
  ruby_block "Add Rolling Restart User's public key" do
    block do
      file = Chef::Util::FileEdit.new(authorized_keys_file)
      file.insert_line_if_no_match(public_key, public_key)
      file.write_file
      only_if { public_key }
    end
  end
else
  file authorized_keys_file do
    owner user
    group user
    mode 0600
    backup false
    content public_key
    only_if { public_key }
  end
end
