# opsworks-rolling-restart cookbook

This cookbook is built to proform a rolling deploy to an application
It creates generic restart scripts to manage adding and removing instances from a load balancer doing a safe restart while the application is out of the load balancer during a deploy

# Requirements
Requires the `node[:rolling_restart][:restart_command]` set by a
wrapper cookbook.

Requires a configured ssh access for a user on an app
instance

# Attributes
`node[:rolling_restart][:restart_command]`
`node[:rolling_restart][:ssh][:user]`
`node[:rolling_restart][:ssh][:public_key]`
`node[:rolling_restart][:load_balancer][:remove_command]`
`node[:rolling_restart][:load_balancer][:add_command]`

# Recipes

`setup`
`default`

# Author

Sport Ngin
