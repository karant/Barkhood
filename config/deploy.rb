# include the Aptana Cloud Capistrano tasks

begin
  require 'aptana_cloud'
rescue LoadError
  puts "This configuration requries aptana_cloud to be installed in order to deploy and the gem can not be found"
  puts "Please install the aptana_cloud gem and rerun your deployment command"
  exit 1
end

set :application, "barkhood"
set :domain, "#{application}.aptanacloud.com"
set :rails_root, "#{File.dirname(__FILE__)}/.."

server domain, :app, :web, :db, :primary => true

# Optional: set user (user used on site). You can also set the
# environment variable APTANA_ID. If neither :user or APTANA_ID is
# set, capistrano will prompt for a user.

# set :user, "karant"

# Optional: set database user and password. You can also set the
# environment variable APTANA_DB_USER and APTANA_DB_PASSWORD. If
# neither is set, capistrano will prompt.

app_credentials = YAML.load_file("#{rails_root}/config/credentials.yml")

# A default user was created when your site was created and these
# credentials are given as the default.

set :db_user, app_credentials['prod_db_username']
set :db_password, app_credentials['prod_db_password']

# You may need this if you need to enter passwords during your deploy

# default_run_options[:pty] = true

# Customizations

# Unless told otherwise, we deploy your current working directory to
# your site.  if you use scm, e.g., subversion or git, uncomment the
# appropriate lines and specify the location of your repository

# subversion

#   set :scm, :subversion

#   Specify your svn repository in the next line the default is the
#   repository setup in your cloud

#   set :repository, "https://#{domain}:39443/svn/repo/trunk"

#   Optionally (and typically) you can use the remote_cache strategy
#   so that your site is checked out directly on your site. You also
#   use the svn export command rather than the (default) checkout so
#   your application directories don't include .svn subdirectories.

#   set :deploy_via, :remote_cache
#   set :checkout, "export"

#   Note that you may need to log in to your site and do at least one
#   svn command in order to accept the self-signed certificate from
#   your secure SVN repository, e.g.,

#   -bash-3.2$ svn info https://#{domain}:39443/svn/repo/trunk  
#   Error validating server certificate for 'https://#{domain}:39443':
#    - The certificate is not issued by a trusted authority. Use the
#      fingerprint to validate the certificate manually!
#   Certificate information:
#    - Hostname: #{domain}
#    - Valid: from ... GMT until ... GMT
#    - Issuer: #{domain}
#    - Fingerprint: ...
#   (R)eject, accept (t)emporarily or accept (p)ermanently? p

# git

  default_run_options[:pty] = true
  set :scm, :git

#   Specify your git repository in the next line the default is the
#   repository setup in your cloud:

  set :repository,  "git@github.com:karant/Barkhood.git"
  set :scm_passphrase, app_credentials['github_deploy_password'] 
  set :branch, "master"

#   Optionally (and typically) you can use the remote_cache strategy
#   so that your site is checked out directly on your site.

  set :deploy_via, :remote_cache

#   Instead, if you don't want your .git directories checked out, you can use

#   set :deploy_via, :export

#   Note that you may need to log into your site and do at least one
#   git command in order to accept the self-signed certificate from
#   your secure SVN repository, e.g.,

#   -bash-3.2$ git ls-remote ssh://#{domain}/var/git/#{application}.git     
#   The authenticity of host '#{domain} (...)' can't be established.
#   RSA key fingerprint is ...
#   Are you sure you want to continue connecting (yes/no)? yes


# Thinking Sphinx
namespace :ultrasphinx do
  task :configure, :roles => [:app] do
    run "cd #{current_path}; rake ultrasphinx:configure RAILS_ENV=#{rails_env}"
  end
  task :index, :roles => [:app] do
    run "cd #{current_path}; rake ultrasphinx:index RAILS_ENV=#{rails_env}"
  end
  task :start, :roles => [:app] do
    run "cd #{current_path}; rake ultrasphinx:daemon:start RAILS_ENV=#{rails_env}"
  end
  task :stop, :roles => [:app] do
    run "cd #{current_path}; rake ultrasphinx:daemon:stop RAILS_ENV=#{rails_env}"
  end
  task :restart, :roles => [:app] do
    run "cd #{current_path}; rake ultrasphinx:daemon:restart RAILS_ENV=#{rails_env}"
  end
end

# http://github.com/jamis/capistrano/blob/master/lib/capistrano/recipes/deploy.rb
# :default -> update, restart
# :update  -> update_code, symlink
namespace :deploy do
  task :before_setup do
    web.disable
  end
  
  task :after_setup do
    # shared_sphinx_folder if rails_env == "production"
  end
  
  task :before_update_code do
    # Stop UltraSphinx before the update so it finds its configuration file.
    ultrasphinx.stop if rails_env == "production"
  end
  
  task :after_update_code do
    symlink_config_yaml_files    
  end

  task :after_symlink do
    symlink_sphinx_indexes if rails_env == "production"
    ultrasphinx.configure if rails_env == "production"
    ultrasphinx.start if rails_env == "production"
    cleanup
  end
  
  task :after_restart do
    web.enable
  end

  desc "Link up Sphinx's indexes."
  task :symlink_sphinx_indexes, :roles => [:app] do
    run "ln -nfs #{shared_path}/config/ultrasphinx #{release_path}/config/ultrasphinx"
    run "ln -nfs #{shared_path}/sphinx #{release_path}/sphinx"
  end
  
  desc "Add the shared folder for sphinx files for the production environment"
  task :shared_sphinx_folder, :roles => :web do
    run "mkdir -p #{shared_path}/config/ultrasphinx"
    run "mkdir -p #{shared_path}/sphinx"
  end 
  
  desc "Link config YAML files with credentials."
  task :symlink_config_yaml_files, :roles => [:app] do
    run "ln -nfs #{shared_path}/config/amazon_s3.yml #{release_path}/config/amazon_s3.yml"   
    run "ln -nfs #{shared_path}/config/credentials.yml #{release_path}/config/credentials.yml"
  end
  
  namespace :web do
    
    desc "Serve up a custom maintenance page."
    task :disable, :roles => :web do
      require 'erb'
      on_rollback { run "rm #{shared_path}/system/maintenance.html"}
      
      reason    = ENV['REASON']
      deadline  = ENV['UNTIL']
      
      template = File.read("app/views/admin/maintenance.html.erb")
      page = ERB.new(template).result(binding)
      
      put page, "#{shared_path}/system/maintenance.html",
                :mode => 0644
    end
  end
end