module SharedSearch
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def delegate_search_permissions_for(*targets, options)
      delegatee = options[:to]

      targets.each do |target|
        include_shared_search_fields target, delegatee

        searchable do
          string :security_type_name, :multiple => true
        end
      end

      define_method :security_type_name do
        delegatee_object = send delegatee
        delegatee_object.security_type_name
      end
    end

    def include_shared_search_fields(target_name, delegatee)
      klass = ModelMap.class_from_type(target_name.to_s)
      params = {}
      if target_name != delegatee
        params[:proc] = proc { |method_name|
          delegatee_object = send delegatee
          method = :"search_#{method_name}"
          if delegatee_object.respond_to? method
            delegatee_object.send method
          end
        }
      end
      define_shared_search_fields(klass.shared_search_fields, delegatee, params)
    end

    def add_search_permissions(current_user, search)
      [Dataset, Workspace, Workfile].each do |klass|
        klass.add_search_permissions(current_user, search)
      end
    end
  end
end
