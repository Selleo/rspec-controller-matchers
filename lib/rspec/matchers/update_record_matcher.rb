RSpec::Matchers.define :update_record do |resource, attributes|
  supports_block_expectations

  match do |actual|
    if using_form?
      allow(form_klass).to receive(:new).and_call_original
      expect_any_instance_of(form_klass).to receive(:save).and_call_original
    end

    first_attribute_key = attributes.keys.first

    initial_matcher = change { resource.reload.public_send(first_attribute_key) }.to(attributes[first_attribute_key])

    update_all_attributes = attributes.except(first_attribute_key).inject(initial_matcher) do |current_matcher, (attribute_name, expected_value)|
        current_matcher.and change { resource.public_send(attribute_name) }.to(expected_value)
    end

    begin
      expect { actual.call }.to update_all_attributes
    rescue RSpec::Expectations::ExpectationNotMetError => e
      @failure_message = "Record not updated."
      return false
    end

    if using_form?
      expect(form_klass).to have_received(:new).with(have_attributes(id: resource.id), kind_of(Hash))
    end

    true
  end

  def using_form(form_klass)
    @form_klass = form_klass
    self
  end

  failure_message do
    @failure_message
  end

  def using_form?
    form_klass.present?
  end

  private

  attr_reader :form_klass, :form
end
