module AresMUSH
  class LedgerRecord < Ohm::Model
    include ObjectModel

    attribute :collection
    attribute :s_data
    reference :char, "AresMUSH::Character"

    index :collection

    def data= data
      self.s_data = JSON(data)
    end

    def data
      JSON.parse(self.s_data || '{}', symbolize_names: true).with_indifferent_access
    end

  end
end
