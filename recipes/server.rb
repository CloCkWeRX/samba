#
# Cookbook Name:: samba
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
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

users = nil
shares = data_bag_item(node["samba"]["shares_data_bag"], "shares")

shares["shares"].each do |k,v|
  if v.has_key?("path")
    directory v["path"] do
      recursive true
    end
  end
end

unless node["samba"]["passdb_backend"] =~ /^ldapsam/
  users = nil #data_bag_item(node["samba"]["users_data_bag"], "shares")
end

package value_for_platform(
  ["ubuntu", "debian", "arch", "centos"] => { "default" => "samba" },
  ["redhat", "fedora", "scientific", "amazon"] => { "default" => "samba3x" },
  "default" => "samba"
)

svcs = value_for_platform(
  "ubuntu" => { "default" => ["smbd", "nmbd"] },
  "debian" => { "default" => ["samba"] },
  ["redhat", "centos", "fedora", "scientific", "amazon"] => { "default" => ["smb", "nmb"] },
  "arch" => { "default" => [ "samba" ] },
  "default" => ["smbd", "nmbd"]
)

svcs.each do |s|
  service s do
    pattern "smbd|nmbd" if node["platform"] =~ /^arch$/
    action [:enable, :start]
  end
end

template node["samba"]["config"] do
  source "smb.conf.erb"
  owner "root"
  group "root"
  mode 00644
  variables :shares => shares["shares"]
  svcs.each do |s|
    notifies :restart, "service[#{s}]"
  end
end

if users
  users.each do |u|
    samba_user u["id"] do
      password u["smbpasswd"]
      action [:create, :enable]
    end if u["smbpasswd"]
  end
end
