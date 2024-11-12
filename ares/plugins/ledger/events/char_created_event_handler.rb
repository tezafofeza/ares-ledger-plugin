module AresMUSH
  module Ledger
    class CharCreatedEventHandler
      def on_event(event)
        char = Character[event.char_id]
        ledger = LedgerRecord.create(char: char)
      end
    end
  end
end
