require 'puppet/route_manager/router'
require 'puppet/checksum'
require 'puppet/file_serving/content'
require 'puppet/file_serving/metadata'

reference = Puppet::Util::Reference.newreference :router, :doc => "Router types and their terminus classes" do
    text = ""
    Puppet::RouteManager::Router.instances.sort { |a,b| a.to_s <=> b.to_s }.each do |router|
        ind = Puppet::RouteManager::Router.instance(router)
        name = router.to_s.capitalize
        text += router.to_s + "\n" + ("-" * name.length) + "\n\n"

        text += ind.doc + "\n\n"

        Puppet::RouteManager::Terminus.terminus_classes(ind.name).sort { |a,b| a.to_s <=> b.to_s }.each do |terminus|
            text += terminus.to_s + "\n" + ("+" * terminus.to_s.length) + "\n\n"

            term_class = Puppet::RouteManager::Terminus.terminus_class(ind.name, terminus)

            text += Puppet::Util::Docs.scrub(term_class.doc) + "\n\n"
        end
    end

    text
end

reference.header = "This is the list of all routers, their associated terminus classes, and how you select between them.

In general, the appropriate terminus class is selected by the application for you (e.g., ``puppetd`` would always use the ``rest``
terminus for most of its indirected classes), but some classes are tunable via normal settings.  These will have ``terminus setting``
documentation listed with them.


"
