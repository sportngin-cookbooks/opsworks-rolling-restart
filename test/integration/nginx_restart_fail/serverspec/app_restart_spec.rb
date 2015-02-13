require 'spec_helper'

describe file('/usr/local/bin/app-restart') do
  it { should be_file }
  it { should contain "RETRIES=10" }
  it { should contain "PORT=81" }
  it { should contain "sleep 10" }
  it { should contain "curl" }
  it { should contain "haproxy-add" }
  it { should contain "haproxy-remove" }
  it { should contain "nginx restart" }
  it { should contain "app_ready"}
  it { should contain "before_command"}
  it { should contain "after_command"}
end

describe command("/usr/local/bin/app-restart") do
  its(:exit_status) { should eq 1 }
end
