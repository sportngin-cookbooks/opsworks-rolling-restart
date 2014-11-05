require 'spec_helper'

describe user('deploy') do
  it { should exist }
  it { should belong_to_group 'opsworks' }
  it { should have_home_directory '/home/deploy' }
  it { should have_authorized_key 'ssh-rsa IAMAPUBLICKEY' }
end
