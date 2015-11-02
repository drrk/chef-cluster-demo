name = "kimball-cluster-lock-demo"

require "chef/provisioning/aws_driver"

with_driver "aws::eu-west-1" do

  aws_key_pair "#{name}-key" do
    allow_overwrite false
    private_key_path "#{ENV['HOME']}/.ssh/#{name}-key"
  end

  aws_security_group "#{name}-ssh" do
    inbound_rules '0.0.0.0/0' => 22
  end

  aws_security_group "#{name}-http" do
    inbound_rules '0.0.0.0/0' => 80
  end

  with_machine_options({
    :aws_tags => {"belongs_to" => name},
    :ssh_username => "ubuntu",
    :bootstrap_options => {
      :image_id => "ami-47360a30",
      :instance_type => "t2.micro",
      :key_name => "#{name}-key",
      :security_group_ids => ["#{name}-ssh","#{name}-http"]
    }
  })

  # track all the instances we need to make
  webservers = 1.upto(3).map { |n| "#{name}-webserver-#{n}" }

  machine_batch do
    webservers.each do |instance|
      machine instance do
        recipe "cluster-demo"
        tag "kimball-cluster-demo"
        converge true
      end
    end
  end

  load_balancer "#{name}-lb" do
    machines webservers
    load_balancer_options({
      :security_groups => "#{name}-http"
    })
  end
end
