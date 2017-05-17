require 'spec_helper'
require 'support/controller_specs_boilerplate'

class User < ActiveRecord::Base
end

describe 'destroy_record matcher', type: :controller do
  context 'when controller destroys given record' do
    controller do
      def destroy
        User.find(params[:id]).destroy
      end
    end

    it 'fulfills expectation when a record was destroyed' do
      user = User.create

      params = {
        id: user
      }

      expect do
        delete(:destroy, params: params)
      end.to destroy_record(user)
    end

    it "fails expectation when record wasn't destroyed" do
      user_1 = User.create
      user_2 = User.create

      params = {
        id: user_1
      }

      expect do
        expect do
          delete(:destroy, params: params)
        end.to destroy_record(user_2)
      end.to fail_including("Record wasn't destroyed.")#raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end

  context 'destroy using service object' do
    class UserService
      def self.call; end
    end

    describe 'fulfills expectation when service receive call' do
      controller do
        def destroy
          User.last.destroy!
          UserService.call
        end
      end

      it do
        user = User.create
        expect do
          delete(:destroy, params: {id:user.id})
        end.to destroy_record(user).using_service(UserService)
      end
    end

    describe "fails expectation when service wasn't called" do
      controller do
        def destroy
          User.last.destroy!
        end
      end

      it do
        user = User.create
        expect do
          expect do
            delete(:destroy, params: {id:user.id})
          end.to destroy_record(user).using_service(UserService)
        end.to fail_including "Record wasn't destroyed using service."
      end
    end
  end
end
