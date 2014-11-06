require 'spec_helper'

describe file('/usr/local/bin/app-restart') do
  it { should be_file }
  it { should contain "TIMEOUT=60" }
  it { should contain "PORT=81" }
  it { should contain "sleep 10" }
  it { should contain "curl" }
  it { should contain "haproxy-add" }
  it { should contain "haproxy-remove" }
  it { should contain "echo restart" }
end

describe file('/usr/local/bin/haproxy-add') do
  it { should be_file }
  it { should contain 'server.*10.0.0.3' }
  it { should contain 'ssh deploy@10.0.0.1' }
  it { should_not contain '10.0.0.2' }
end

describe file('/usr/local/bin/haproxy-remove') do
  it { should be_file }
  it { should contain 'server.*10.0.0.3' }
  it { should contain 'ssh deploy@10.0.0.1' }
  it { should_not contain '10.0.0.2' }
end
