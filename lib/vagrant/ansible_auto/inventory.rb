# frozen_string_literal: true
require 'set'
require 'json'
require 'vagrant/ansible_auto/host'

module VagrantPlugins
  module AnsibleAuto
    class Inventory
      def groups
        @groups = Hash.new { |hash, key| hash[key] = Set.new } if unset?(@groups)
        @groups
      end

      def hosts
        @hosts = Set.new if unset?(@hosts)
        @hosts
      end

      def vars
        @vars = Hash.new { |hash, key| hash[key] = {} } if unset?(@vars)
        @vars
      end

      def children
        @children = Hash.new { |hash, key| hash[key] = Set.new } if unset?(@children)
        @children
      end

      def groups=(new_groups)
        @groups = nil

        new_groups.each do |group_heading, entries|
          group, type = group_heading.to_s.split(':')
          case type
          when 'vars'
              entries = {} if entries.nil?
              vars_for(group, entries)
          when 'children'
              entries = [] if entries.nil?
              children_of(group, *entries)
            else
              entries = [] if entries.nil?
              add_group(group, *entries)
          end
        end

        groups
      end

      def hosts=(_new_hosts)
        @hosts = nil

        news_hosts.each do |host, hostvars|
          hostvars = {} if hostvars.nil?
          add_host(host, hostvars)
        end

        hosts
      end

      def vars=(new_vars)
        @vars = nil

        new_vars.each_pair do |group, group_vars|
          vars_for(group, group_vars)
        end

        vars
      end

      def children=(new_children)
        @children = nil

        new_children.each_pair do |group, group_children|
          children_of(group, *group_children)
        end

        children
      end

      def add_group(group, *members)
        groups[group.to_s].tap do |group_members|
          group_members.merge(members)
          return group_members
        end
      end

      def add_host(host, hostvars = {})
        hosts.add case host
                  when Host
                    host
                  when String, Symbol
                    Host.new(host, hostvars)
                  else
                    HostMachine.new(host, hostvars)
                  end
      end

      def vars_for(group, new_vars = {})
        vars[group.to_s].tap do |group_vars|
          group_vars.merge!(new_vars)
          return group_vars
        end
      end

      def children_of(group, *new_children)
        children[group.to_s].tap do |group_children|
          group_children.merge(new_children.map(&:to_s))
          return group_children
        end
      end

      def merge!(other)
        @groups = groups.merge(other.groups) do |_group, group_members, other_group_members|
          group_members.merge(other_group_members)
        end

        @vars = vars.merge(other.vars) do |_group, group_vars, other_group_vars|
          group_vars.merge(other_group_vars)
        end

        @children = children.merge(other.children) do |_group, group_children, other_group_children|
          group_children.merge(other_group_children)
        end

        self
      end

      def merge(other)
        clone.merge!(other)
      end

      def hostvars
        hosts.each_with_object({}) { |host, acc| acc.merge!(host.hostvars) }
      end

      def to_h
        $stderr.puts vars.inspect
        {}.tap do |h|
          h.merge!(Hash[groups.map { |group, members| [group, members.to_a] }])
          h['_'] = hosts.map(&:to_h)
          h.merge!(Hash[vars.map { |group, group_vars| ["#{group}:vars", group_vars] }])
          h.merge!(Hash[children.map { |group, group_children| ["#{group}:children", group_children.to_a] }])
        end
      end

      def to_json
        to_h.tap do |h|
          h.delete('_')
          h['_meta'] = hostvars
        end.to_json
      end

      def to_ini
        with_ini_lines.to_a.join("\n")
      end

      def with_ini_lines
        return enum_for(__method__) unless block_given?

        [with_ini_lines_hosts, with_ini_lines_groups].each do |e|
          e.each { |line| yield line }
        end
      end

      def with_ini_lines_hosts
        return enum_for(__method__) unless block_given?
        hosts.each { |host| yield host.to_ini }
      end

      def with_ini_lines_groups
        return enum_for(__method__) unless block_given?

        to_h.tap { |h| h.delete('_') }.each do |group, entries|
          yield "[#{group}]"

          (entries.is_a?(Hash) ? entries.map { |entry, value| "#{entry}=#{value}" } : entries).each do |entry|
            yield entry
          end
        end
      end

    private

      def unset?(obj)
        defined?(obj).nil? or obj.nil?
      end
    end
  end
end
