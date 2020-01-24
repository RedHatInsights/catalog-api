class ApplicationPolicy
  include Api::V1::Mixins::ACEMixin
  ADMINISTRATOR_ROLE_NAME = 'Catalog Administrator'.freeze
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def catalog_administrator?
    @admin ||= Insights::API::Common::RBAC::Roles.assigned_role?(ADMINISTRATOR_ROLE_NAME)
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def resource_check?(verb)
    return true unless Insights::API::Common::RBAC::Access.enabled?
    return true if catalog_administrator?
    access_id_list(verb).include?(record.id.to_s)
  end

  def access_id_list(verb)
    access_obj = Insights::API::Common::RBAC::Access.new(record.class.table_name, verb).process
    raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{record.class}" unless access_obj.accessible?

    ace_ids(verb, record.class)
  end

  def permission_check?(verb)
    if Insights::API::Common::RBAC::Access.enabled?
      Insights::API::Common::RBAC::Access.new(record.class.table_name, verb).process.accessible?
    else
      true
    end
  end

  class Scope
    include Api::V1::Mixins::ACEMixin
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def catalog_administrator?
      @admin ||= Insights::API::Common::RBAC::Roles.assigned_role?(ADMINISTRATOR_ROLE_NAME)
    end

    def resolve
      if !Insights::API::Common::RBAC::Access.enabled? || catalog_administrator?
        scope.all
      else
        access_obj = Insights::API::Common::RBAC::Access.new(scope.table_name, 'read').process
        raise Catalog::NotAuthorized, "Not Authorized for #{scope}" unless access_obj.accessible?
        if access_obj.owner_scoped?
          scope.by_owner
        else
            ids = ace_ids('read', scope)
            if scope.try(:supports_access_control?)
              scope.where(:id => ids)
            else
              scope
            end
          end
      end
    end
  end
end
