

module RubyAsync
  class << self
    def async(accounts)
      result = []
      Async do |task|
      accounts.each do |account|
        task.async do
          resp = account.get_ecobank_account_balance
    
          result << { id: account.id, name: account.name }.merge(resp["availableBalance"])
        end
      end
      result
    end

    def accounts
      @@accounts ||= 6.times.map do |i|
        index = i + 1
        Account.new(index, "Account #{index}", "1234567890")
      end
    end
  end

  Struct.new("Account", :id, :name, :account_number)
end
