# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'


class CurateGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)


  desc """
This generator makes the following changes to your application:
 1. Runs required generators
 2. Adds curate behaviors to ApplicationController
 3. Adds the curate routes
 4. Adds a user migration
       """
  # Implement the required interface for Rails::Generators::Migration.
  # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
  def self.next_migration_number(path)
    if @prev_migration_nr
      @prev_migration_nr += 1
    else
      if last_migration = Dir[File.join(path, '*.rb')].sort.last
        @prev_migration_nr = last_migration.sub(File.join(path, '/'), '').to_i + 1
      else
        @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
      end
    end
    @prev_migration_nr.to_s
  end

  def run_required_generators
    generate "blacklight --devise"
    generate "hydra:head -f"
    generate "sufia:models:install"
  end

  # Add behaviors to the application controller
  def inject_controller_behavior
    controller_name = "ApplicationController"
    file_path = "app/controllers/application_controller.rb"
    if File.exists?(file_path)
      insert_into_file file_path, :after => 'include Blacklight::Controller' do
        "\n  include CurateController\n"
      end
      gsub_file file_path, "layout 'blacklight'", ""
    else
      puts "     \e[31mFailure\e[0m  Could not find #{file_path}.  To add Curate behaviors to your ApplicationController, you must include the CurateController module in the ApplicationController class definition."

    end
  end

  def remove_catalog_controller
    say_status("warning", "Removing Blacklight's generated CatalogController...It will cause you grief", :yellow)
    remove_file('app/controllers/catalog_controller.rb')
  end

  # Setup the database migrations
  def copy_migrations
    [
      'add_terms_of_service_to_user.rb',
      'add_user_force_update_profile.rb',
      'create_help_requests.rb'
    ].each do |file|
      migration_template "migrations/#{file}", "db/migrate/#{file}"
    end
  end

  # The engine routes have to come after the devise routes so that /users/sign_in will work
  def inject_routes
    routing_code = "\n  curate_for containers: [:generic_works]\n"
    sentinel = /devise_for :users/
    inject_into_file 'config/routes.rb', routing_code, { :after => sentinel, :verbose => false }
    gsub_file 'config/routes.rb', /^\s+root.+$/, "  root 'welcome#index'"
  end

  # This enables our registrations controller to run the after_update_path_for hook.
  def update_devise_route
    gsub_file 'config/routes.rb', /^\s+devise_for :users/, '  devise_for :users, controllers: { sessions: :sessions, registrations: :registrations }'
  end


  def create_recipients_list
    create_file('config/recipients_list.yml', "---\n- hello@world.com\n")
  end

  def inject_curate_user
    inject_into_class 'app/models/user.rb', 'User' do
      "\n  include Curate::User\n"
    end
  end

  def remove_catalog_controller
    say_status("warning", "Removing Blacklight's generated CatalogController...It will cause you grief", :yellow)
    remove_file('app/controllers/catalog_controller.rb')
  end

end