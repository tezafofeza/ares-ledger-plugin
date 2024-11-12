module AresMUSH
  module Ledger
    class UnlockLedgerEntryHandler

      def handle(request)
        char = Character[request.args[:char_id]]
        data = request.args
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error
        return { error: t('ledger.invalid_character') } if !char

        collection = Ledger.config.dig(:collections, data[:collection])
        return { error: t('ledger.invalid_collection') } if !collection

        entry = Ledger.get_entry data[:collection], char, data[:uuid]
        return { error: t('ledger.no_entry_found') } if !entry

        res = Ledger.unlock_entry data[:collection], enactor, char, data[:uuid]
        return { error: res } if res.is_a? String
        res
      end

    end
  end
end
