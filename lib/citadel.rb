#
# Copyright 2013-2016, Balanced, Inc.
# Copyright 2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/http'
require 'chef/json_compat'
require 'aws-sdk-core'

# Helper to access files in a private S3 bucket using an interface like Chef
# node attributes.
#
# @since 1.0.0
# @example
#   template '/etc/myapp.conf' do
#     variables password: citadel['myapp/password']
#   end
class Citadel
  autoload :ChefDSL, 'citadel/chef_dsl'
  autoload :CitadelError, 'citadel/error'
  autoload :VERSION, 'citadel/version'

  attr_reader :bucket, :region, :credentials

  def initialize(node, bucket=nil, region=nil)
    @node = node
    @bucket = bucket || node['citadel']['bucket']
    @region = region || node['citadel']['region']
    @credentials = find_credentials
  end

  def find_credentials
    if @node['citadel']['access_key_id']
      Aws::Credentials.new(
        access_key_id: @node['citadel']['access_key_id'],
        secret_access_key: @node['citadel']['secret_access_key'],
        token: @node['citadel']['token'],
      )
    elsif @node['citadel']['assume_role']
      Aws::AssumeRoleCredentials.new(
        role_arn: @node['citadel']['assume_role'],
        role_session_name: "citadel-#{@node['name']}"
      )
    end
  end

  def [](key)
    Chef::Log.debug("citadel: Retrieving #{@bucket}/#{key}")
    client = if @credentials.nil?
                Aws::S3::Client.new(region: @region)
              else
                Aws::S3::Client.new(credentials: @credentials, region: @region)
              end
    client.get_object(bucket: @bucket, key: key).body.string
  end
end
