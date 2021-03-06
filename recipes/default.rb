#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Cookbook Name:: transmission
# Recipe:: default
#
# Copyright:: 2011-2015, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "transmission::#{node['transmission']['install_method']}"

%w(bencode i18n transmission-simple activesupport).each do |pkg|
  chef_gem pkg do
    action :install
    compile_time true if Chef::Resource::ChefGem.method_defined?(:compile_time)
  end
end

require 'transmission-simple'

template 'transmission-default' do
  case node['platform_family']
  when 'rhel', 'fedora'
    path '/etc/sysconfig/transmission-daemon'
  else
    path '/etc/default/transmission-daemon'
  end
  source 'transmission-daemon.default.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/init.d/transmission-daemon' do
  source 'transmission-daemon.init.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

service 'transmission' do
  service_name 'transmission-daemon'
  supports restart: true, reload: true
  action [:enable, :start]
end

directory '/etc/transmission-daemon' do
  owner 'root'
  group node['transmission']['group']
  mode '0755'
end

template "#{node['transmission']['config_dir']}/settings.json" do
  source 'settings.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :reload, 'service[transmission]', :immediately
end

link '/etc/transmission-daemon/settings.json' do
  to "#{node['transmission']['config_dir']}/settings.json"
  not_if { File.symlink?("#{node['transmission']['config_dir']}/settings.json") }
end
