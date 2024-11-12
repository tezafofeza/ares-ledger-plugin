require 'securerandom'

module AresMUSH
  module Ledger

    def self.get_default_roles collection, action
      universal = config(collection)&.dig(:collection_role) || config[:universal_role] || 'admin'
      {
        has_stack: ['approved'],
        lock: [universal],
        add: ['owner', universal],
        edit: ['owner', universal],
        view: ['everyone'],
        delete: ['owner', universal]
      }[action]
    end

    def self.has_stack_role collection, enactor, char, stack, action
      stack = get_stack collection, stack
      return false if !stack
      return true if enactor && enactor.is_admin?
      roles = stack[action] || get_default_roles(collection, action)
      roles = roles.is_a?(Array) ? roles : [roles]
      roles.select { |r|
        return true if r == 'everyone'
        return true if r == 'owner' && enactor&.id == char.id
        enactor && enactor.has_role?(r)
      }.first != nil
    end

    def self.get_stack_permissions collection, enactor, char, stack
      {
        has_stack: has_stack_role(collection, char, char, stack, :has_stack),
        lock: has_stack_role(collection, enactor, char, stack, :lock),
        add: has_stack_role(collection, enactor, char, stack, :add),
        edit: has_stack_role(collection, enactor, char, stack, :edit),
        view: has_stack_role(collection, enactor, char, stack, :view),
        delete: has_stack_role(collection, enactor, char, stack, :delete)
      }
    end

    def self.get_uuid
      SecureRandom.uuid
    end

    def self.config collection = nil
      ledger = Global.read_config('ledger').with_indifferent_access
      return ledger[:collections][collection] if ledger.dig(:collections, collection)
      ledger
    end

    def self.normalize_fields fields
      fields.map { |f| { key: f[:name].gsub(/[- ]/, '_').downcase, name: f[:name], type: f[:type] || 'input', select: f[:select] } }
    end

    def self.get_fields collection, stack_name
      stack = get_stack collection, stack_name
      fields = {}
      if stack[:templates]
        stack[:templates].each { |t| fields[t] = normalize_fields(config[t][:fields]) }
      else
        fields[stack_name] = normalize_fields(stack[:fields])
      end
      fields
    end

    def self.get_character_ledger_collection collection, char
      ledger = LedgerRecord.find(collection: collection, char_id: char.id).first
      if !ledger
        ledger = LedgerRecord.create(collection: collection, char: char)
      end
      ledger
    end

    def self.get_stack collection, stack
      config(collection)&.dig(:stacks, stack) if stack
    end

    def self.build_ledger_view enactor, char
      config[:collections].with_indifferent_access.keys.map { |key|
        c_collection = config(key)
        has_collection = (c_collection[:has_collection] || ['everyone'])
        has_collection = has_collection.is_a?(Array) ? has_collection : [has_collection]
        next if !has_collection.select { |r| enactor&.has_role? r }.first
        collection = get_character_ledger_collection key, char
        out = {}
        c_collection[:stacks].keys.each { |k|
          next if !has_stack_role(key, enactor, char, k, :view) || !has_stack_role(key, char, char, k, :has_stack)
          out[k] = get_stack(key, k).dup
          out[k][:fields] = get_fields(key, k).dup
          out[k].merge!(get_stack_permissions(key, enactor, char, k))
          if out[k][:templates]
            out[k][:template_config] = out[k][:templates].map { |t|
              [
                t,
                { display: config[t][:display] || out[k][:display],
                  table_fields: config[t][:table_fields] || out[k][:table_fields]
                }
              ]
            }.to_h
            out[k][:templates] = out[k][:templates].map { |t| [t, config[t][:templates]] }.to_h
          end
          out[k][:entries] = {}
        }
        collection.data.each { |k, v|
          next if !has_stack_role key, char, char, k, :has_stack
          if has_stack_role key, enactor, char, k, :view
            out[k][:entries] = v.sort_by { |k, v| "#{v[:created_at]}" }.to_h
          end
        }
        { title: c_collection[:title] || key, order: c_collection[:order], stacks: out }
      }.compact
    end

    def self.normalized_template_name template
      "ledger_#{(template || '').gsub(/[- ]/, '_').downcase}"
    end

    def self.is_numeric? str
      ("#{str}" || '').match?(/^[+-]?(\d*[.])?\d+$/)
    end

  end
end
