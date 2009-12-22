require 'puppet/route_manager/router'
require 'puppet/checksum'
require 'puppet/file_serving/content'
require 'puppet/file_serving/metadata'

reference = Puppet::Util::Reference.newreference :router, :doc => "Router types and their repository classes" do
    text = ""
    Puppet::RouteManager::Router.instances.sort { |a,b| a.to_s <=> b.to_s }.each do |router|
        ind = Puppet::RouteManager::Router.instance(router)
        name = router.to_s.capitalize
        text += router.to_s + "\n" + ("-" * name.length) + "\n\n"

        text += ind.doc + "\n\n"

        Puppet::RouteManager::Repository.repository_classes(ind.name).sort { |a,b| a.to_s <=> b.to_s }.each do |repository|
            text += repository.to_s + "\n" + ("+" * repository.to_s.length) + "\n\n"

            term_class = Puppet::RouteManager::Repository.repository_class(ind.name, repository)

            text += Puppet::Util::Docs.scrub(term_class.doc) + "\n\n"
        end
    end

    text
end

reference.header = "This is the list of all routers, their associated repository classes, and how you select between them.

In general, the appropriate repository class is selected by the application for you (e.g., ``puppetd`` would always use the ``rest``
repository for most of its indirected classes), but some classes are tunable via normal settings.  These will have ``repository setting``
documentation listed with them.


"
