module AresMUSH
  module Ledger
    class AddLedgerEntryHandler

      def handle(request)
        char = Character[request.args[:char_id]]
        data = request.args
        enactor = request.enactor

        error = Website.check_login(request)
        return error if error
        return { error: t('ledger.invalid_character') } if !char

        collection = Ledger.config.dig(:collections, data[:collection])
        return { error: t('ledger.invalid_collection') } if !collection

        stack = Ledger.get_stack data[:collection], data[:stack]
        return { error: t('ledger.invalid_stack') } if !stack

        template = Ledger.get_fields(data[:collection], data[:stack])&.dig(data[:template].empty? ? data[:stack] : data[:template])
        return { error: t('ledger.invalid_template') } if !template

        entry = data[:entry].slice(*template&.map{ |t| t[:key].to_sym })
        return { error: t('ledger.invalid_entry_input') } if entry.empty?

        entry.each { |k, v|
          entry[k] = v if v.is_a? Array
          entry[k] = 'true' == v if ['true', 'false'].include? v
          entry[k] = ("#{v.to_f}" == v ? v.to_f : v.to_i) if Ledger.is_numeric? v
        }

        template.select { |t| t[:type] == 'text' }.each { |t|
          entry["md_#{t[:key]}"] = Website.format_markdown_for_html(entry[t[:key]])
        }

        entry.merge!({ _stack: data[:stack], _template: data[:template], created_at: DateTime.now, updated_at: DateTime.now })
        res = Ledger.add_entry data[:collection], enactor, char, data[:stack], entry
        return { error: res } if res.is_a? String
        res
      end

    end
  end
end
