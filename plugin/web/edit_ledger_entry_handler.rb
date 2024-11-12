module AresMUSH
  module Ledger
    class EditLedgerEntryHandler

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

        data[:edit].each { |k, v|
          data[:edit][k] = v if v.is_a? Array
          data[:edit][k] = 'true' == v if ['true', 'false'].include? v
          data[:edit][k] = ("#{v.to_f}" == v ? v.to_f : v.to_i) if Ledger.is_numeric? v
        }

        field = (entry[:_template].nil? ||entry[:_template].empty?) ? entry[:_stack] : entry[:_template]
        template = Ledger.get_fields(data[:collection], entry[:_stack])&.dig(field)
        edit = data[:edit].slice(*template&.map{ |t| t[:key].to_sym })
        return { error: t('ledger.invalid_data') } if edit.empty?

        template.select { |t| t[:type] == 'text' }.each { |t|
          edit["md_#{t[:key]}"] = Website.format_markdown_for_html(edit[t[:key]])
        }

        edit.merge!({ _stack: entry[:_stack], _template: entry[:_template], uuid: entry[:uuid], updated_at: DateTime.now })
        res = Ledger.edit_entry data[:collection], enactor, char, entry[:uuid], edit
        return { error: res } if res.is_a? String
        res
      end

    end
  end
end
