# Install/remove a Datadog integration
# This resource basically wraps the datadog-agent integration command to be able
# to install and remove integrations from a Chef recipe.
# The datadog_resource must be used on a system where the datadog-agent has
# already been setup.

require 'chef/mixin/shell_out'

default_action :install

property :property_name, String, name_property: true
property :version, String, required: true

action :install do
  unless node['datadog']['agent6']
    Chef::Log.error('The datadog_integration resource is only available with Agent v6.')
    return
  end

  Chef::Log.debug("Getting integration #{new_resource.property_name}")

  execute 'integration install' do
    command   "\"#{agent_exe_filepath}\" integration install #{new_resource.property_name}==#{new_resource.version}"
    user      'dd-agent' unless node['platform_family'] == 'windows'

    not_if {
      output = shell_out("#{agent_exe_filepath} integration show -q #{new_resource.property_name}").stdout
      output.strip == new_resource.version
    }
  end
end

action :remove do
  unless node['datadog']['agent6']
    Chef::Log.error('The datadog_integration resource is only available with Agent v6.')
    return
  end

  Chef::Log.debug("Removing integration #{new_resource.property_name}")

  execute 'integration remove' do
    command   "\"#{agent_exe_filepath}\" integration remove #{new_resource.property_name}"
    user      'dd-agent' unless node['platform_family'] == 'windows'

    not_if {
      output = shell_out("#{agent_exe_filepath} integration show -q #{new_resource.property_name}").stdout
      output.strip.empty?
    }
  end
end

def agent_exe_filepath
  if node['platform_family'] == 'windows'
    # The Windows Agent will always be setup in this path if the _install-windows.rb
    # has been used to install it.
    "C:\\Program\ Files\\Datadog\\Datadog\ Agent\\embedded\\agent.exe"
  else
    '/opt/datadog-agent/bin/agent/agent'
  end
end
