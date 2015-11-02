name = "kimball-cluster-lock-demo"

require 'chef/provisioning/aws_driver'
with_driver 'aws::eu-west-1'

machine_batch do
  action :destroy
  machines 1.upto(3).map { |n| "#{name}-webserver-#{n}" }
end
