#
# Cookbook Name:: cluster-demo
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
#include_recipe 'cluster-demo::setup'

ENV["AWS_REGION"] = "eu-west-1"
ls = Locksmith.new(node['cluster-demo']['aws']['key'],node['cluster-demo']['aws']['secret'],"Locks")

# Simple test to demonstrate what we can do with this, we are going to stop apache, wait 2 minutes and then start it again.
# This will cause all the instances behind the load balancer to go down at once, until we add the lock

Chef.event_handler do
  on :converge_start do
    ls.create("apacherestart",:ttl=>360, :attempts => 60, :wait_time => 10000)
  end
end
Chef.event_handler do
  on :converge_complete do
    ls.delete("apacherestart")
  end
end

log "Stoping apache for maintenance"

execute 'stop-apache' do
  command '/usr/sbin/service apache2 stop'
  action :run
end

ruby_block 'sleep' do
  block do
    sleep 60
  end
end

log "Restarting apache"

execute 'start-apache' do
  command '/usr/sbin/service apache2 start'
  action :run
end
