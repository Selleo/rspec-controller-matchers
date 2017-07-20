require "spec_helper"
require "support/controller_specs_boilerplate"

class User < ActiveRecord::Base
end

describe "update_record matcher", type: :controller do
  context "when controller updates a record with given attributes" do
    controller do
      def update
        User.find(params[:id]).update(user_params)
      end

      private

      def user_params
        params.require(:user).permit(:name, :age)
      end
    end

    it "ensures that appropriate record is updated with the correct attributes" do
      user = User.create(name: "Sophia", age: 20)

      params = {
        id: user.id,
        user: {
          name: "Emily",
          age: 30
        }
      }

      expect do
        post(:update, params: params)
      end.to update_record(user, name: "Emily", age: 30)
    end
  end

  context "when controller does not update" do
    controller do
      def update
        User.find(params[:id]).update(name: "Emily")
      end
    end

    it "fails with a proper message if an attributes is not updated" do
      user = User.create(name: "Sophia", age: 20)

      params = {
        id: user.id,
        user: {
          name: "Emily",
          age: 30
        }
      }

      expect do
        expect do
          post(:update, params: params)
        end.to update_record(user, name: "Emily", age: 30)
      end.to fail_with <<~MESSAGE.strip.squeeze(" ")
        Expected a record of a User class with id = #{user.id} to be updated, \
        but the following attribute was not properly changed:
        "age" from 20 to 30
      MESSAGE
    end

    it "fails with a proper messages if more than one attribute is not updated" do
      user = User.create(name: "Sophia", age: 20)

      params = {
        id: user.id,
        user: {
          name: "Diana",
          age: 30
        }
      }

      expect do
        expect do
          post(:update, params: params)
        end.to update_record(user, name: "Diana", age: 30)
      end.to fail_with <<~MESSAGE.strip.squeeze(" ")
        Expected a record of a User class with id = #{user.id} to be updated, \
        but the following attributes were not properly changed:
        "name" from "Sophia" to "Diana" (it was changed to "Emily")
        "age" from 20 to 30
      MESSAGE
    end
  end

  context "when record is updated using proper form object" do
    controller do
      def update
        UserForm.new(user, user_params).save
      end

      def update_with_fireworks
        UserForm.new(user, user_params).update_with_fireworks
      end

      def update_age
        UserForm.new(user, user_params).update_age
      end

      def update_name
        UserForm.new(user, user_params).update_name
      end

      private

      def user
        User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:name, :age)
      end
    end

    before do
      routes.draw do
        post "update" => "anonymous#update"
        post "update_with_fireworks" => "anonymous#update_with_fireworks"
        post "update_age" => "anonymous#update_age"
        post "update_name" => "anonymous#update_name"
      end
    end

    class UserForm
      def initialize(user, new_attributes)
        @user = user
        @new_attributes = new_attributes
      end

      def save
        user.update(new_attributes)
      end

      def update_with_fireworks
        # Here be dragons
        user.update(new_attributes)
      end

      def update_age
        user.update(new_attributes.slice(:age))
      end

      def update_name
        user.update(new_attributes.slice(:name))
      end

      private

      attr_reader :user, :new_attributes
    end

    it "ensures that appropriate object is updated using appropriate form object" do
      user = User.create(name: "Emily", age: 20)
      params = {
        id: user.id,
        user: {
          name: "Sophie",
          age: 30
        }
      }

      expect do
        post(:update, params: params)
      end.to update_record(user, name: "Sophie", age: 30).using_form(UserForm)
    end

    it "does not assume any specific form object interface name" do
      user = User.create(name: "Emily", age: 20)
      params = {
        id: user.id,
        user: {
          name: "Sophie",
          age: 30
        }
      }

      expect do
        post(:update_with_fireworks, params: params)
      end.to update_record(user, name: "Sophie", age: 30).using_form(UserForm)
    end

    it "does not assume a single form object method call" do
      user = User.create(name: "Emily", age: 20)
      params = {
        id: user.id,
        user: {
          name: "Sophie",
          age: 30
        }
      }

      expect do
        post(:update_age, params: params)
        post(:update_name, params: params)
      end.to update_record(user, name: "Sophie", age: 30).using_form(UserForm)
    end
  end

  context "when record is updated without using proper form object" do
    controller do
      def update_one_with_form
        UserForm.new(user, user_params.slice(:name)).save
        user.update(user_params.slice(:age))
      end

      def update_without_form
        user.update(user_params)
      end

      private

      def user
        User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:name, :age)
      end
    end

    before do
      routes.draw do
        post "update_one_with_form" => "anonymous#update_one_with_form"
        post "update_without_form" => "anonymous#update_without_form"
      end
    end

    class UserForm
      def initialize(user, new_attributes)
        @user = user
        @new_attributes = new_attributes
      end

      def save
        user.update(new_attributes)
      end

      private

      attr_reader :user, :new_attributes
    end

    it "fails with a proper message if an attribute is updated without using proper form object" do
      user = User.create(name: "Emily", age: 20)
      params = {
        id: user.id,
        user: {
          name: "Sophie",
          age: 30
        }
      }

      expect do
        expect do
          post(:update_one_with_form, params: params)
        end.to update_record(user, name: "Sophie", age: 30).using_form(UserForm)
      end.to fail_with <<~MESSAGE.strip.squeeze(" ")
        Expected a record of a User class with id = #{user.id} to be updated using UserForm, \
        but the following attribute was changed by some other means:
        "age"
      MESSAGE
    end

    it "fails with a proper message if all attributes are updated without using proper form object" do
      user = User.create(name: "Emily", age: 20)
      params = {
        id: user.id,
        user: {
          name: "Sophie",
          age: 30
        }
      }

      expect do
        expect do
          post(:update_without_form, params: params)
        end.to update_record(user, name: "Sophie", age: 30).using_form(UserForm)
      end.to fail_with <<~MESSAGE.strip.squeeze(" ")
        Expected a record of a User class with id = #{user.id} to be updated using UserForm, \
        but the following attributes were changed by some other means:
        "name"
        "age"
      MESSAGE
    end

    it "fails with a proper message if attributes are updated to a wrong value and without form" do
      user = User.create(name: "Emily", age: 20)
      params = {
        id: user.id,
        user: {
          name: "Diana",
          age: 25
        }
      }

      expect do
        expect do
          post(:update_without_form, params: params)
        end.to update_record(user, name: "Sophie", age: 30).using_form(UserForm)
      end.to fail_with <<~MESSAGE.strip.squeeze(" ")
        Expected a record of a User class with id = #{user.id} to be updated, \
        but the following attributes were not properly changed:
        "name" from "Emily" to "Sophie" (it was changed to "Diana")
        "age" from 20 to 30 (it was changed to 25)

        Expected a record of a User class with id = #{user.id} to be updated using UserForm, \
        but the following attributes were changed by some other means:
        "name"
        "age"
      MESSAGE
    end
  end
end
