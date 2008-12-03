class MultiMigrationGenerator < Rails::Generator::NamedBase
  
  attr_accessor :database_name
  
  def initialize(runtime_args, runtime_options = {})
    @database_name = runtime_args.shift
    super
  end
  
  def manifest
    # puts get_local_assigns.inspect
    record do |m|
      m.migration_template 'migration.rb', "db/migrate/#{database_name.downcase}", :assigns => get_local_assigns
    end
  end
  
  protected
  
    def banner
      "Usage: #{$0} multi_migration DBName MigrationName [options]"
    end
  
  private  
    def get_local_assigns
      returning(assigns = {}) do
        if class_name.underscore =~ /^(add|remove)_.*_(?:to|from)_(.*)/
          assigns[:migration_action] = $1
          assigns[:table_name]       = $2.pluralize
        else
          assigns[:attributes] = []
        end
      end
    end
end