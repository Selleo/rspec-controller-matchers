RSpec::Matchers.define :destroy_record do |record|
  supports_block_expectations

  match do |actual|
    @failure_message = nil

    if using_service?
      allow(service_klass).to receive(:call).and_wrap_original do |original_method, *args, &block|
        begin
          expect { original_method.call(*args, &block) }.to change { record.class.exists?(id: record.id) }.to(false)
        rescue RSpec::Expectations::ExpectationNotMetError
          @failure_message = "Expected a record of #{record.class.name} class to be destroyed with service object #{service_klass.name}, but was not"
          return false
        end
      end
    end

    begin
      expect {
        actual.call
      }.to change { record.class.exists?(id: record.id) }.to(false)
    rescue RSpec::Expectations::ExpectationNotMetError
      @failure_message = "Expected a record of #{record.class.name} class to be destroyed, but was not"
      return false
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
