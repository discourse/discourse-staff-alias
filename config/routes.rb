require_dependency "discourse_staff_alias_constraint"

DiscourseStaffAlias::Engine.routes.draw do
  get "/" => "discourse_staff_alias#index", constraints: DiscourseStaffAliasConstraint.new
  get "/actions" => "actions#index", constraints: DiscourseStaffAliasConstraint.new
  get "/actions/:id" => "actions#show", constraints: DiscourseStaffAliasConstraint.new
end
