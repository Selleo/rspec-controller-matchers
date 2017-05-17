require 'spec_helper'
require 'support/controller_specs_boilerplate'
require 'rspec/matchers/fail_matchers'

class User < ActiveRecord::Base; end
class Account < User; end

describe 'be_record matcher', type: :model do
  context 'records with same classes and primary keys' do
    it 'ensures that a compared records are the same' do
      expect(User.create(name: 'Adams')).to be_record(User.find_by(name: 'Adams'))
    end
  end

  context 'when records have different classes' do
    it 'fails expectation when records are not equal - have different classes' do
      expect do
        expect(Account.create(name: 'Bank')).to be_record(User.create(name: 'Adams'))
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end

  context 'when records have different primary keys' do
    it 'fails expectation when records are not equal - have different ids' do
      expect do
        expect(User.create(name: 'Adams')).to be_record(User.create(name: 'Michael'))
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end
end
