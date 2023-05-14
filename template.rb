# rails new app-name --database=postgresql -T --skip-sprockets -J

def add_vite
  run "bundle exec vite install"

  say "[+] Downloading vite.config.js", :yellow
  remove_file "vite.config.js"
  run "wget -nv -O vite.config.js https://raw.githubusercontent.com/H4K1/rails-template/master/templates/vite.config.js"
end

def react_import
  say "[+] Installing React", :yellow
  run "yarn add react react-dom"

  say "[+] Importing React on the application.html.erb", :yellow
  gsub_file "app/views/layouts/application.html.erb", /<%= vite_javascript_tag 'application' %>\n/,
    "<%= vite_javascript_tag 'application.jsx' %>"
  gsub_file "app/views/layouts/application.html.erb", /<%= stylesheet_link_tag 'application', media: 'all' %>\n/, ""
end

def react_templates
  say "[+] Copying React app", :yellow
  from = "https://github.com/H4K1/rails-template/trunk/templates/frontend/"
  to = "app/frontend"

  run "rm -rf app/frontend"

  run "svn checkout #{from} #{to} --force"
end

def generate_root
  say "[+] Generating root page", :yellow
  generate(:controller, "pages", "index")
  run 'echo "" > app/views/pages/index.html.erb'
  inject_into_file "app/views/pages/index.html.erb", '<div id="root"></div>'
  route "root to: 'pages#index'"
end

def add_react
  react_import
  react_templates
  generate_root
end

def add_tests
  say "[+] Adding test gems", :yellow
  run "bundle exec rails generate rspec:install"
  run "bundle exec rails generate annotate:install"

  from = "https://github.com/H4K1/rails-template/trunk/templates/spec/support"
  to = "spec/support"

  inject_into_file "spec/rails_helper.rb", after: "require 'rspec/rails'\n" do
    <<~EOF
      Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }
    EOF
  end

  run "svn checkout #{from} #{to} --force"
end

def copy_gemfile
  say "[+] Downloading Gemfile template", :yellow
  remove_file "Gemfile"
  run "wget -nv https://raw.githubusercontent.com/H4K1/rails-template/master/templates/Gemfile"
end

def copy_templates
  copy_gemfile
end

def add_app_config
  inject_into_file "config/application.rb", after: "class Application < Rails::Application\n" do
    <<-EOF
    config.generators do |g|
      g.fixtures = false
      g.view_specs = false
      g.helper_specs = false
      g.routing_specs = false
      g.template_engine = :haml
      g.assets = false
      g.helper = false
    end
    EOF
  end
end

def welcome_message
  say "\n\n\n\n"
  say "Welcome to the Rails template!", :green
  say "You can getting started with the following commands:", :green
  say "\tforeman start -f Procfile.dev"
  say "\n\n"
  say "You can convert all html to haml with the following command:", :green
  say "\tHAML_RAILS_DELETE_ERB=true rails haml:erb2haml"
end

add_app_config
copy_templates

after_bundle do
  add_vite
  add_react
  add_tests

  welcome_message
end
