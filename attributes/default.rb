default[:rolling_restart][:ssh][:user] = 'deploy'
default[:rolling_restart][:ssh][:group] = 'opsworks'

default[:rolling_restart][:restart_command] = 'sh rolling_restart'
