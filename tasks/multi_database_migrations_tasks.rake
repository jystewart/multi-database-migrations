namespace :db do
  namespace :multi do
    desc "Migrate through the scripts in db/migrate/<dbname>/ Target specific version with VERSION=x. Turn off output with VERBOSE=false."
    task :migrate => :environment do
      raise "DATABASE is required" unless ENV['DATABASE']
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations["#{ENV['DATABASE']}_#{RAILS_ENV}"])
      ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      ActiveRecord::Migrator.migrate("db/migrate/#{ENV['DATABASE']}", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    end
    
    namespace :migrate do
      desc  'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x'
      task :redo => [ 'db:multi:rollback', 'db:multi:migrate' ]

      desc 'Resets your database using your migrations for the current environment'
      task :reset => ["db:multi:drop", "db:multi:create", "db:multi:migrate"]

      desc 'Runs the "up" for a given migration VERSION.'
      task :up => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        raise "DATABASE is required" unless ENV['DATABASE']
        ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations["#{ENV['DATABASE']}_#{RAILS_ENV}"])
        ActiveRecord::Migrator.run(:up, "db/migrate/#{ENV['DATABASE']}", version)
        Rake::Task["db:multi:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end

      desc 'Runs the "down" for a given migration VERSION.'
      task :down => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        raise "DATABASE is required" unless ENV['DATABASE']
        ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations["#{ENV['DATABASE']}_#{RAILS_ENV}"])
        ActiveRecord::Migrator.run(:down, "db/migrate/#{ENV['DATABASE']}", version)
        Rake::Task["db:multi:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
      end
    end
    
    desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
    task :rollback => :environment do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      raise "DATABASE is required" unless ENV['DATABASE']
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations["#{ENV['DATABASE']}_#{RAILS_ENV}"])
      ActiveRecord::Migrator.rollback("db/migrate/#{ENV['DATABASE']}", step)
      Rake::Task["db:multi:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
    end

    
    namespace :schema do
      desc "Create a db/schema.rb file that can be portably used against any DB supported by AR"
      task :dump => :environment do
        raise "DATABASE is required" unless ENV['DATABASE']
        ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations["#{ENV['DATABASE']}_#{RAILS_ENV}"])
        
        require 'active_record/schema_dumper'
        File.open(ENV['SCHEMA'] || "db/schema_#{ENV["DATABASE"]}.rb", "w") do |file|
          ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
        end
      end

      desc "Load a schema.rb file into the database"
      task :load => :environment do
        raise "DATABASE is required" unless ENV['DATABASE']
        ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations["#{ENV['DATABASE']}_#{RAILS_ENV}"])
        file = ENV['SCHEMA'] || "db/schema_#{ENV['DATABASE']}.rb"
        load(file)
      end
    end
    
  end
end
