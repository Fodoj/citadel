chef_gem 'aws-sdk' do
  compile_time true
  version node['aws']['aws_sdk_version'] if node.key? 'aws'
end
