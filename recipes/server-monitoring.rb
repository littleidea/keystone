#
# Cookbook Name:: keystone
# Recipe:: server-monitoring
#
# Copyright 2009, Rackspace Hosting, Inc.
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

########################################
# BEGIN COLLECTD SECTION
# Allow for enable/disable of collectd
if node["enable_collectd"]
  include_recipe "collectd-graphite::collectd-client"

  ks_service_endpoint = get_bind_endpoint("keystone", "service-api")
  keystone = get_settings_by_roles("keystone", "keystone")
  keystone_admin_user = keystone["admin_user"]
  keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
  keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]

  cookbook_file File.join(node['collectd']['plugin_dir'], "keystone_plugin.py") do
    source "keystone_plugin.py"
    owner "root"
    group "root"
    mode "0644"
  end

  collectd_python_plugin "keystone_plugin" do
    options(
      "Username"=>keystone_admin_user,
      "Password"=>keystone_admin_password,
      "TenantName"=>keystone_admin_tenant,
      "AuthURL"=>ks_service_endpoint["uri"]
    )
  end
end
########################################


########################################
# BEGIN MONIT SECTION
# Allow for enable/disable of monit
if node["enable_monit"]
  include_recipe "monit::server"
  platform_options = node["keystone"]["platform"]

  monit_procmon "keystone" do
    process_name "keystone-all"
    start_cmd "/usr/sbin/service " + platform_options["keystone_service"] + " start"
    stop_cmd "/usr/sbin/service " + platform_options["keystone_service"] + " stop"
  end
end
########################################
