module Internal
  class UsersQuery
    def self.call(relation: User.all, options: {})
      role, search = options.values_at(:role, :search)

      relation = relation.with_role(role, :any) if role.presence
      relation = search_relation(relation, search) if search.presence

      relation.order("created_at DESC")
    end

    def self.search_relation(relation, search)
      relation.where("users.name ILIKE :search OR
      users.username ILIKE :search OR
      users.github_username ILIKE :search OR
      users.email ILIKE :search OR
      users.twitter_username ILIKE :search", search: "%#{search.strip}%")
    end
  end
end
