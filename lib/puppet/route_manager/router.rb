require 'puppet/util/docs'
require 'puppet/route_manager/envelope'
require 'puppet/route_manager/request'
require 'puppet/util/cacher'

# The class that connects functional classes with their different collection
# back-ends.  Each router has a set of associated repository classes,
# each of which is a subclass of Puppet::RouteManager::Repository.
class Puppet::RouteManager::Router
    include Puppet::Util::Cacher
    include Puppet::Util::Docs

    @@routers = []

    # Find an router by name.  This is provided so that Repository classes
    # can specifically hook up with the routers they are associated with.
    def self.instance(name)
        @@routers.find { |i| i.name == name }
    end

    # Return a list of all known routers.  Used to generate the
    # reference.
    def self.instances
        @@routers.collect { |i| i.name }
    end

    # Find an indirected model by name.  This is provided so that Repository classes
    # can specifically hook up with the routers they are associated with.
    def self.model(name)
        return nil unless match = @@routers.find { |i| i.name == name }
        match.model
    end

    attr_accessor :name, :model

    # Create and return our cache repository.
    def cache
        raise(Puppet::DevError, "Tried to cache when no cache class was set") unless cache_class
        repository(cache_class)
    end

    # Should we use a cache?
    def cache?
        cache_class ? true : false
    end

    attr_reader :cache_class
    # Define a repository class to be used for caching.
    def cache_class=(class_name)
        validate_repository_class(class_name) if class_name
        @cache_class = class_name
    end

    # This is only used for testing.
    def delete
        @@routers.delete(self) if @@routers.include?(self)
    end

    # Set the time-to-live for instances created through this router.
    def ttl=(value)
        raise ArgumentError, "Router TTL must be an integer" unless value.is_a?(Fixnum)
        @ttl = value
    end

    # Default to the runinterval for the ttl.
    def ttl
        unless defined?(@ttl)
            @ttl = Puppet[:runinterval].to_i
        end
        @ttl
    end

    # Calculate the expiration date for a returned instance.
    def expiration
        Time.now + ttl
    end

    # Generate the full doc string.
    def doc
        text = ""

        if defined? @doc and @doc
            text += scrub(@doc) + "\n\n"
        end

        if s = repository_setting()
            text += "* **Repository Setting**: %s" % repository_setting
        end

        text
    end

    def initialize(model, name, options = {})
        @model = model
        @name = name

        @cache_class = nil
        @repository_class = nil

        raise(ArgumentError, "Router %s is already defined" % @name) if @@routers.find { |i| i.name == @name }
        @@routers << self

        if mod = options[:extend]
            extend(mod)
            options.delete(:extend)
        end

        # This is currently only used for cache_class and repository_class.
        options.each do |name, value|
            begin
                send(name.to_s + "=", value)
            rescue NoMethodError
                raise ArgumentError, "%s is not a valid Router parameter" % name
            end
        end
    end

    # Set up our request object.
    def request(method, key, arguments = nil)
        Puppet::RouteManager::Request.new(self.name, method, key, arguments)
    end

    # Return the singleton repository for this router.
    def repository(repository_name = nil)
        # Get the name of the repository.
        unless repository_name ||= repository_class
            raise Puppet::DevError, "No repository specified for %s; cannot redirect" % self.name
        end

        return termini[repository_name] ||= make_repository(repository_name)
    end

    # This can be used to select the repository class.
    attr_accessor :repository_setting

    # Determine the repository class.
    def repository_class
        unless @repository_class
            if setting = self.repository_setting
                self.repository_class = Puppet.settings[setting].to_sym
            else
                raise Puppet::DevError, "No repository class nor repository setting was provided for router %s" % self.name
            end
        end
        @repository_class
    end

    # Specify the repository class to use.
    def repository_class=(klass)
        validate_repository_class(klass)
        @repository_class = klass
    end

    # This is used by repository_class= and cache=.
    def validate_repository_class(repository_class)
        unless repository_class and repository_class.to_s != ""
            raise ArgumentError, "Invalid repository name %s" % repository_class.inspect
        end
        unless Puppet::RouteManager::Repository.repository_class(self.name, repository_class)
            raise ArgumentError, "Could not find repository %s for router %s" % [repository_class, self.name]
        end
    end

    # Expire a cached object, if one is cached.  Note that we don't actually
    # remove it, we expire it and write it back out to disk.  This way people
    # can still use the expired object if they want.
    def expire(key, *args)
        request = request(:expire, key, *args)

        return nil unless cache?

        return nil unless instance = cache.find(request(:find, key, *args))

        Puppet.info "Expiring the %s cache of %s" % [self.name, instance.name]

        # Set an expiration date in the past
        instance.expiration = Time.now - 60

        cache.save(request(:save, instance, *args))
    end

    # Search for an instance in the appropriate repository, caching the
    # results if caching is configured..
    def find(key, *args)
        request = request(:find, key, *args)
        repository = prepare(request)

        begin
            if result = find_in_cache(request)
                return result
            end
        rescue => detail
            puts detail.backtrace if Puppet[:trace]
            Puppet.err "Cached %s for %s failed: %s" % [self.name, request.key, detail]
        end

        # Otherwise, return the result from the repository, caching if appropriate.
        if ! request.ignore_repository? and result = repository.find(request)
            result.expiration ||= self.expiration
            if cache? and request.use_cache?
                Puppet.info "Caching %s for %s" % [self.name, request.key]
                cache.save request(:save, result, *args)
            end

            return repository.respond_to?(:filter) ? repository.filter(result) : result
        end

        return nil
    end

    def find_in_cache(request)
        # See if our instance is in the cache and up to date.
        return nil unless cache? and ! request.ignore_cache? and cached = cache.find(request)
        if cached.expired?
            Puppet.info "Not using expired %s for %s from cache; expired at %s" % [self.name, request.key, cached.expiration]
            return nil
        end

        Puppet.debug "Using cached %s for %s" % [self.name, request.key]
        return cached
    end

    # Remove something via the repository.
    def destroy(key, *args)
        request = request(:destroy, key, *args)
        repository = prepare(request)

        result = repository.destroy(request)

        if cache? and cached = cache.find(request(:find, key, *args))
            # Reuse the existing request, since it's equivalent.
            cache.destroy(request)
        end

        result
    end

    # Search for more than one instance.  Should always return an array.
    def search(key, *args)
        request = request(:search, key, *args)
        repository = prepare(request)

        if result = repository.search(request)
            raise Puppet::DevError, "Search results from repository %s are not an array" % repository.name unless result.is_a?(Array)
            result.each do |instance|
                instance.expiration ||= self.expiration
            end
            return result
        end
    end

    # Save the instance in the appropriate repository.  This method is
    # normally an instance method on the indirected class.
    def save(instance, *args)
        request = request(:save, instance, *args)
        repository = prepare(request)

        result = repository.save(request)

        # If caching is enabled, save our document there
        cache.save(request) if cache?

        result
    end

    private

    # Check authorization if there's a hook available; fail if there is one
    # and it returns false.
    def check_authorization(request, repository)
        # At this point, we're assuming authorization makes no sense without
        # client information.
        return unless request.node

        # This is only to authorize via a repository-specific authorization hook.
        return unless repository.respond_to?(:authorized?)

        unless repository.authorized?(request)
            msg = "Not authorized to call %s on %s" % [request.method, request.to_s]
            unless request.options.empty?
                msg += " with %s" % request.options.inspect
            end
            raise ArgumentError, msg
        end
    end

    # Setup a request, pick the appropriate repository, check the request's authorization, and return it.
    def prepare(request)
        # Pick our repository.
        if respond_to?(:select_repository)
            unless repository_name = select_repository(request)
                raise ArgumentError, "Could not determine appropriate repository for %s" % request
            end
        else
            repository_name = repository_class
        end

        dest_repository = repository(repository_name)
        check_authorization(request, dest_repository)

        return dest_repository
    end

    # Create a new repository instance.
    def make_repository(repository_class)
        # Load our repository class.
        unless klass = Puppet::RouteManager::Repository.repository_class(self.name, repository_class)
            raise ArgumentError, "Could not find repository %s for router %s" % [repository_class, self.name]
        end
        return klass.new
    end

    # Cache our repository instances indefinitely, but make it easy to clean them up.
    cached_attr(:termini) { Hash.new }
end
