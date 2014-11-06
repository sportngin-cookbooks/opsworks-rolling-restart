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

file "#{home_dir}/.ssh/authorized_keys" do
  owner user
  group group
  mode 0700
  backup false
  content public_key
end if public_key