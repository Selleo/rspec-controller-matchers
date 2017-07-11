RSpec::Matchers.define :be_record do |record|
  match do |actual|
    @failure_message = nil

    begin
      expect(actual).to be_kind_of(record.class)
    rescue RSpec::Expectations::ExpectationNotMetError
      @failure_message = "Expected the record to be kind of #{record.class} but was #{actual.class} instead."
      return false
    end

    begin
      expect(actual).to have_attributes(record.class.primary_key => record[record.class.primary_key])
    rescue RSpec::Expectations::ExpectationNotMetError
      @failure_message = "Expected id of the record to eql #{record.id} but was #{actual.id}"
      return false
    end

    true
  end

  failure_message do
    @failure_message
  end
end
