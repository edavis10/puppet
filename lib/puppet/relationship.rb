#!/usr/bin/env ruby
#
#  Created by Luke A. Kanies on 2006-11-24.
#  Copyright (c) 2006. All rights reserved.

# subscriptions are permanent associations determining how different
# objects react to an event

require 'puppet/util/pson'

# This is Puppet's class for modeling edges in its configuration graph.
# It used to be a subclass of GRATR::Edge, but that class has weird hash
# overrides that dramatically slow down the graphing.
class Puppet::Relationship
    extend Puppet::Util::Pson
    attr_accessor :source, :target, :callback

    attr_reader :event

    def self.from_pson(pson)
        source = pson["source"]
        target = pson["target"]

        args = {}
        if event = pson["event"]
            args[:event] = event
        end
        if callback = pson["callback"]
            args[:callback] = callback
        end

        new(source, target, args)
    end

    attr_reader :event, :type

    RELATIONSHIP_TYPES = [:container, :dependency]

    # Sort dependency edges before container edges.
    # Otherwise, sort alphabetically
    def <=>(other)
        if self.type == other.type
            weight = (self.target.weight <=> other.target.weight)
            return weight unless weight == 0
            return (self.target.to_s <=> other.target.to_s)
        end

        return -1 if dependency?
        return 1 # We're a container; we lose
    end
    
    def container?
        type == :container
    end

    def dependency?
        type == :dependency
    end

    def event=(event)
        if event != :NONE and ! callback
            raise ArgumentError, "You must pass a callback for non-NONE events"
        end
        @event = event
    end

    def initialize(source, target, options = {})
        @source, @target = source, target

        options = (options || {}).inject({}) { |h,a| h[a[0].to_sym] = a[1]; h }

        # Default to a 'container' type relationship
        @type = :container
        [:callback, :event, :type].each do |option|
            if value = options[option]
                send(option.to_s + "=", value)
            end
        end
    end

    # Does the passed event match our event?  This is where the meaning
    # of :NONE comes from.
    def match?(event)
        if self.event.nil? or event == :NONE or self.event == :NONE
            return false
        elsif self.event == :ALL_EVENTS or event == self.event
            return true
        else
            return false
        end
    end

    def label
        result = {}
        result[:callback] = callback if callback
        result[:event] = event if event
        result
    end

    def ref
        "%s => %s" % [source, target]
    end

    def to_pson_data_hash
        data = {
            'source' => source.to_s,
            'target' => target.to_s
        }

        ["event", "callback"].each do |attr|
            next unless value = send(attr)
            data[attr] = value
        end
        data
    end

    def to_pson(*args)
        to_pson_data_hash.to_pson(*args)
    end

    def to_s
        ref
    end

    def type=(value)
        raise ArgumentError, "Invalid relationship type %s; valid values are %s" % [value, RELATIONSHIP_TYPES.inspect] unless RELATIONSHIP_TYPES.include?(value)

        @type = value
    end
end
