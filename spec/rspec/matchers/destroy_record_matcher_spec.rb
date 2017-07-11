require "spec_helper"
require "support/controller_specs_boilerplate"
require "rspec/matchers/fail_matchers"

class User < ActiveRecord::Base
end

describe "destroy_record matcher", type: :controller do
  context "controller destroys a record" do
    controller do
      def destroy
        user = User.find(params[:id])
        user.destroy
      end
    end

    it "ensures that correct object is destroyed" do
      user = User.create
      params = { id: user.id }

      expect do
        delete(:destroy, params: params)
      end.to destroy_record(user)
    end
  end

  context "controller destroys a record using service object" do
    class DestroyUser
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def self.call(user)
        new(user).call
      end

      def call
        user.destroy
      end
    end

    controller do
      def destroy
        user = User.find(params[:id])
        DestroyUser.call(user)
      end
    end

    it "ensures that correct object is destroyed by correct service object" do
      user = User.create
      params = { id: user.id }

      expect do
        delete(:destroy, params: params)
      end.to destroy_record(user).using_service(DestroyUser)
    end
  end

  context "controller does not remove a record" do
    controller do
      def destroy
      end
    end

    it "fails if record was not destroyed" do
      user = User.create
      params = { id: user.id }

      expect do
        expect do
          delete(:destroy, params: params)
        end.to destroy_record(user)
      end.to fail_with("Expected a record of User class to be destroyed, but was not")
    end
  end

  context "controller destroys record" do
    class NotDestroyUser
      def self.call(user)
      end
    end

    controller do
      def destroy
        user = User.find(params[:id])
        NotDestroyUser.call(user)
        user.destroy
      end
    end

    it "fails if record is not destroyed by service object" do
      user = User.create
      params = { id: user.id }

      expect do
        expect do
          delete(:destroy, params: params)
        end.to destroy_record(user).using_service(NotDestroyUser)
      end.to fail_with("Expected a record of User class to be destroyed with service object NotDestroyUser, but was not")
    end
  end
end
