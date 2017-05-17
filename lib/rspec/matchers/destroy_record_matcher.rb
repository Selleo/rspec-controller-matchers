

RSpec::Matchers.define :destroy_record do |record|
  supports_block_expectations

  match do |actual|
    if using_service?
      allow(service_klass).to receive(:call).and_call_original
    end

    actual.call

    begin
      expect(record.class.exists?(id: record.id)).to eq false
    rescue RSpec::Expectations::ExpectationNotMetError => e
      @failure_message = "Record wasn't destroyed. \n"
      @failure_message << e.message
      return false
    end

    if using_service?
      begin
        expect(service_klass).to have_received(:call)
      rescue RSpec::Expectations::ExpectationNotMetError => e
        @failure_message = "Record wasn't destroyed using service. \n"
        @failure_message << e.message
        return false
      end
    end

    true
  end

  def using_service(klass)
    @service_klass = klass
    self
  end

  failure_message do
    @failure_message
  end


  private

  attr_reader :service_klass

  def using_service?
    service_klass.present?
  end
end
