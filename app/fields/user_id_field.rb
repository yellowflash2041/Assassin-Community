require "administrate/field/base"

class UserIdField < Administrate::Field::Base
  def find_user_id
    data
  end

  def render_label
    if attribute == :rewarder_id
      "Rewarder ID"
    else
      "User ID"
    end
  end
end
