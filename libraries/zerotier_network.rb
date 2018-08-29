require "chef/log"
require "uri"
require "mixlib/shellout"
require "net/http"
require "net/https"
require "json"

module ChefZerotierCookbook
    class ZerotierNetwork < Chef::Resource
        resource_name :zerotier_network

        default_action :join

        # Set the properties for the resource
        property :network_id, String, name_property: true, required: true
        property :node_name, String, required: true
        property :auth_token, String, required: true
        property :central_url, String, default: "https://my.zerotier.com"

        action :join do
            if ::File.exists?(format("/var/lib/zerotier-one/networks.d/%s.conf", new_resource.network_id))
                Chef::Log.info(format("Network %s already joined. Skipping.", new_resource.network_id))
            else
                join = Mixlib::ShellOut.new(format("/usr/sbin/zerotier-cli join %s", new_resource.network_id))
                join.run_command
                raise format("Error joining network %s", new_resource.network_id) if join.error?

                if new_resource.auth_token
                    url = URI.parse(format("%s/api/network/%s/member/%s/", new_resource.central_url, new_resource.network_id, node['zerotier']['node_id']))
                   
                    netinfo = {
                        networkId: new_resource.network_id,
                        nodeId: node["zerotier"]["node_id"],
                        name: new_resource.node_name,
                        config: {
                            nwid: new_resource.network_id,
                            authorized: true
                        }
                    }

                    response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == "https") do |http|
                        post = Net::HTTP::Post.new(url, "Content-Type" => "application/json")
                        post.add_field("Authorization", format("Bearer %s", new_resource.auth_token))
                        post.body = netinfo.to_json
                        http.request(post)
                    end

                    case response
                    when Net::HTTPSuccess
                        # do nothing
                    else
                        leave = Mixlib::ShellOut.new(format("/usr/sbin/zerotier-cli leave %s", new_resource.network_id))
                        leave.run_command
                        error = JSON.parse(response.body)
                        raise format("Error %s authorizing network: %s: %s", response.code. error["type"], error["message"])
                    end
                end
                
            end
        end

        action :leave do
            if ::File.exists?(format("/var/lib/zerotier-one/networks.d/%s.conf", new_resource.network_id))
                converge_by(format("Leaving network %s", new_resource.network_id)) do
                    leave = Mixlib::ShellOut.new(format("/usr/sbin/zerotier-cli leave %s", new_resource.network_id))
                    leave.run_command
                    raise format("Error leaving network %s", new_resource.network_id) if leave.error?
                end
            else
                Chef::Log.warn(format("Network %s is not joined. Skipping", new_resource.network_id))
            end
        end
    end
end