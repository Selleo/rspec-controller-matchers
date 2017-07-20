RSpec::Matchers.define :update_record do |resource, expected_attributes|
  supports_block_expectations

  # Creating a proxy wrapper for form, with a minimum possible public API, to allow for proxying all method calls
  class FormWrapper < BasicObject
    def initialize(form_object, expected_attributes_keys, changed_attributes_reference, resource)
      @form_object = form_object
      @expected_attributes_keys = expected_attributes_keys
      @changed_attributes_reference = changed_attributes_reference
      @resource = resource
    end

    def method_missing(method_name, *args, &block)
      initial_attributes = @expected_attributes_keys.each_with_object({}) do |attribute_name, attributes|
        attributes[attribute_name] = @resource.public_send(attribute_name)
      end

      @form_object.send(method_name, *args, &block)
      @resource.reload

      @expected_attributes_keys.each do |attribute_name|
        attribute_changed = initial_attributes[attribute_name] != @resource.public_send(attribute_name)

        @changed_attributes_reference << attribute_name if attribute_changed
      end
    end
  end

  match do |actual|
    @failure_message = nil
    @resource = resource
    @expected_attributes = expected_attributes
    @names_of_attributes_changed_by_form = Set.new

    if using_form?
      allow(form_class).to receive(:new).and_wrap_original do |method, *args, &block|
        form_object = method.call(*args, &block)
        FormWrapper.new(form_object, expected_attributes.keys, names_of_attributes_changed_by_form, resource)
      end
    end

    @initial_attributes = current_attributes

    actual.call
    resource.reload

    @final_attributes = current_attributes

    check_if_attributes_were_changed_to_expected_values
    check_if_attributes_were_changed_using_form if using_form?

    failure_message.blank?
  end

  failure_message do
    @failure_message
  end

  def using_form(form_class)
    @form_class = form_class
    self
  end

  def using_form?
    form_class.present?
  end

  private

  attr_reader :form_class,
              :resource,
              :expected_attributes,
              :names_of_attributes_changed_by_form,
              :initial_attributes,
              :final_attributes

  def current_attributes
    expected_attributes.keys.each_with_object({}) do |attribute_name, attributes|
      attributes[attribute_name] = resource.public_send(attribute_name)
    end
  end

  def add_error_message(message)
    if failure_message.present?
      failure_message << "\n" * 2
    else
      @failure_message = ""
    end

    failure_message << message
  end

  def check_if_attributes_were_changed_to_expected_values
    attributes_not_changed_to_expected_values = expected_attributes.select do |attribute_name, expected_attribute_value|
      final_attributes[attribute_name] != expected_attribute_value
    end

    return if attributes_not_changed_to_expected_values.blank?

    messages = attributes_not_changed_to_expected_values.keys.map do |attribute_name|
      message_attribute_not_changed_to_expected_value(attribute_name)
    end

    add_error_message <<~MESSAGE.strip.squeeze(" ")
      Expected a record of a #{resource.class} class with id = #{resource.id} to be updated, but the following \
      #{messages.one? ? "attribute was" : "attributes were"} not properly changed:
      #{messages.join("\n")}
    MESSAGE
  end

  def message_attribute_not_changed_to_expected_value(attribute_name)
    initial_value = initial_attributes[attribute_name]
    final_value = final_attributes[attribute_name]
    expected_value = expected_attributes[attribute_name]

    message = "#{attribute_name.to_s.inspect} from #{initial_value.inspect} to #{expected_value.inspect}"
    message << " (it was changed to #{final_value.inspect})" if initial_value != final_value
    message
  end

  def check_if_attributes_were_changed_using_form
    changed_attributes = initial_attributes.select do |attribute_name, initial_attribute_value|
      final_attributes[attribute_name] != initial_attribute_value
    end

    names_of_attributes_changed_not_by_form = Set.new(changed_attributes.keys) - names_of_attributes_changed_by_form

    return if names_of_attributes_changed_not_by_form.blank?

    messages = names_of_attributes_changed_not_by_form.map { |attribute_name| attribute_name.to_s.inspect }

    add_error_message <<~MESSAGE.strip.squeeze(" ")
      Expected a record of a #{resource.class} class with id = #{resource.id} to \
      be updated using #{form_class}, but the following \
      #{messages.one? ? "attribute was" : "attributes were"} changed by some other means:
      #{messages.join("\n")}
    MESSAGE
  end
end
