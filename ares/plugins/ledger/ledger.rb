$:.unshift File.dirname(__FILE__)

module AresMUSH
  module Ledger

    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config('ledger', 'shortcuts')
    end

    def self.get_cmd_handler(client, cmd, enactor)
      nil
    end

    def self.get_event_handler(event_name)
      nil
    end

    def self.get_web_request_handler(request)
      case request.cmd
      when 'addLedgerEntry'
        return AddLedgerEntryHandler
      when 'editLedgerEntry'
        return EditLedgerEntryHandler
      when 'deleteLedgerEntry'
        return DeleteLedgerEntryHandler
      when 'lockLedgerEntry'
        return LockLedgerEntryHandler
      when 'unlockLedgerEntry'
        return UnlockLedgerEntryHandler
      else
        nil
      end
    end

  end
end
