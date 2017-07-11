require "spec_helper"
require "support/controller_specs_boilerplate"

describe "update_record matcher", type: :controller do
  class User < ActiveRecord::Base
  end

  context 'without form' do
    context 'checks if updated' do
      controller do
        def update
          User.find(params[:id]).update(user_params)
        end

        def user_params
          params.require(:user).permit(:email)
        end
      end

      it 'works' do
        u = User.create(email: "old@email.ru")
        params = { id: u.id, user: { email: "new_email@mail.dev"} }
        expect do
          put :update, params: params
        end.to update_record(u, email: "new_email@mail.dev")
      end
    end

    context 'checks if updated' do
      controller do
        def update
        end
      end

      it 'fails with message' do
        u = User.create(email: "old@email.ru")
        params = { id: u.id, user: { email: "new_email@mail.dev"} }
        expect do
          expect do
            put :update, params: params
          end.to update_record(u, email: "new_email@mail.dev")
        end.to fail_with("Record not updated.")
      end
    end
  end

  context 'with form' do
    class UserForm
      def initialize(user, attributes)
        @user = user
        user.attributes = attributes
      end

      def save
        @user.save
      end
    end

    context 'checks if updated' do
      controller do
        def update
          UserForm.new(User.find(params[:id]), { email: user_params[:email] }).save
        end

        def user_params
          params.require(:user).permit(:email)
        end
      end

      it 'works' do
        u = User.create(email: "old@email.ru")
        params = { id: u.id, user: { email: "new_email@mail.dev"} }
        expect do
          put :update, params: params
        end.to update_record(u, email: "new_email@mail.dev").using_form(UserForm)
      end
    end
  end
end
