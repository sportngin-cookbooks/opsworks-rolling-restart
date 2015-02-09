require 'spec_helper'

describe command("/usr/local/bin/app-restart") do
  its(:exit_status) { should eq 1 }
end
