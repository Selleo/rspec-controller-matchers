require 'spec_helper'
require 'support/controller_specs_boilerplate'

class User < ActiveRecord::Base; end

describe 'update_record matcher', type: :controller do
  controller do
    def update
      user = User.find(params[:id])
      user.update!(user_params)
    end

    def user_params
      params.require(:user).permit(:name)
    end
  end

  context 'when controller properly updates given record' do
    it 'fulfills expectation when a record was updated' do
      user = User.create(name: 'Walter')
      params = {
        id: user,
        user: {
          name: 'Abraham'
        }
      }
      expect do
        put(:update, params: params)
      end.to update_record(user, name: 'Abraham')
    end
  end

  context 'when attribute is not changed as expected' do
    it 'fails expectation when a record is unchanged' do
      user_1 = User.create(name: 'Walter')
      user_2 = User.create(name: 'Kevin')
      params = {
        id: user_2,
        user: {
          name: 'Abraham'
        }
      }
      expect do
        expect do
          put(:update, params: params)
        end.to update_record(user_1, name: 'Abraham')
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end
end
