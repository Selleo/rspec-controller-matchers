require "spec_helper"
require "support/controller_specs_boilerplate"

class User < ActiveRecord::Base; end
class DummyClass < User; end

describe "be_record matcher" do
  context "with example to pass" do
    it "ensures that record is of correct kind" do
      user = User.create(name: "John")

      expect(user).to be_record(User.last)
    end

    it "ensures that record primary key match" do
      user = User.create(name: "Alex")

      expect(user).to be_record(user)
    end
  end

  context "with example to fail" do
    it "ensures that record is of correct kind" do
      user = User.create(name: "John")

      expect do
        expect(user).to be_record(DummyClass.last)
      end.to fail_with("Expected the record to be kind of DummyClass but was User instead.")
    end

    it "ensures that record primary key match" do
      user = User.create(name: "Alex")
      last_user = User.create(name: "Michael")

      expect do
        expect(user).to be_record(last_user)
      end.to fail_with("Expected id of the record to eql #{last_user.id} but was #{user.id}")
    end
  end
end
