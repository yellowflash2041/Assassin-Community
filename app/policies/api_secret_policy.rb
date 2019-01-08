class ApiSecretPolicy < ApplicationPolicy
  def create?
    true
  end

  def destroy?
    user_is_owner?
  end

  def permitted_attributes
    %i[description]
  end

  private

  def user_is_owner?
    user.id == record.user_id
  end
end
