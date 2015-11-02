node.default['apt']['compile_time_update'] = true
include_recipe 'apt'
package "build-essential" do
  action :nothing
end.run_action(:install)
package "zlib1g-dev" do
  action :nothing
end.run_action(:install)

chef_gem 'aws-sdk-v1' do
  compile_time true
end

package "apache2"

template "/var/www/html/index.html" do
  source "index.html.erb"
end

service "apache2" do
  action [:enable, :start]
end
