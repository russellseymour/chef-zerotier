name 'zerotier'
maintainer 'Grant Limberg'
maintainer_email 'grant.limberg@zerotier.com'
license 'GPL v3'
description 'Installs/Configures ZeroTier'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.0.8'
issues_url 'https://github.com/zerotier/chef-zerotier/issues' if respond_to?(:issues_url)
source_url 'https://github.com/zerotier/chef-zerotier' if respond_to?(:source_url)

%w(redhat centos amazon ubuntu debian).each do |os|
    supports os
end

depends 'ohai'
