module AresMUSH
  module Ledger

    def self.get_entry collection, char, uuid
      entry = nil
      ledger = get_character_ledger_collection collection, char
      uuid = uuid.to_sym
      ledger.data.each { |stack, entries| entry = entries[uuid] if entries[uuid] }
      return entry
    end

    def self.view_entry collection, enactor, char, stack, entry
      entry if !has_stack_role collection, enactor, char, stack, :view
    end

    def self.add_entry collection, enactor, char, stack, entry
      return t('ledger.permission_denied') if !has_stack_role collection, enactor, char, stack, :add
      ledger = get_character_ledger_collection collection, char
      data = ledger.data
      data[stack] = {} if !data[stack]
      entry[:uuid] = get_uuid
      data[stack][entry[:uuid]] = entry
      ledger.update(data: data)
      data[stack][entry[:uuid]]
    end

    def self.edit_entry collection, enactor, char, uuid, new_entry
      ledger, data, stack, entry = get_entry_data collection, enactor, char, uuid
      return ledger if ledger.is_a? String
      return t('ledger.cannot_edit_locked_entry') if data[stack][entry[:uuid]][:locked]
      data[stack][entry[:uuid]] = new_entry
      ledger.update(data: data)
      data[stack][entry[:uuid]]
    end

    def self.delete_entry collection, enactor, char, uuid
      ledger, data, stack, entry = get_entry_data collection, enactor, char, uuid
      return ledger if ledger.is_a? String
      data[stack].delete(uuid)
      ledger.update(data: data)
      entry
    end

    def self.unlock_entry collection, enactor, char, uuid
      ledger, data, stack, entry = get_entry_data collection, enactor, char, uuid
      return ledger if ledger.is_a? String
      data[stack][entry[:uuid]] = data[stack][entry[:uuid]].except(:locked, :locked_on, :locked_by)
      ledger.update(data: data)
      data[stack][entry[:uuid]]
    end

    def self.lock_entry collection, enactor, char, uuid
      ledger, data, stack, entry = get_entry_data collection, enactor, char, uuid
      return ledger if ledger.is_a? String
      return t('ledger.entry_already_locked') if data[stack][entry[:uuid]][:locked]
      data[stack][entry[:uuid]].merge!(
        { locked: true, locked_on: DateTime.now, locked_by: { name: enactor.name, id: enactor.id }}
      )
      ledger.update(data: data)
      data[stack][entry[:uuid]]
    end

    def self.get_entry_data collection, enactor, char, uuid
      ledger = get_character_ledger_collection collection, char
      entry = get_entry collection, char, uuid
      data = ledger.data
      stack = entry[:_stack]
      return t('ledger.permission_denied') if entry[:locked] && !has_stack_role(collection, enactor, char, entry[:_stack], :lock)
      return t('ledger.no_entry_found') if !data[stack][entry[:uuid]]
      return ledger, data, stack, entry
    end

  end
end
