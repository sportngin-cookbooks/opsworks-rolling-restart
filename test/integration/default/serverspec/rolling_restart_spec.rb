require 'spec_helper'

describe file('/usr/local/bin/rolling_restart') do
  it { should be_file }
  it { should be_grouped_into 'opsworks' }
  it { should be_owned_by 'deploy'}
  it { should contain '10.0.0.1', '10.0.0.2' }
  it { should_not contain '10.0.0.3', '10.0.0.4' }
end

