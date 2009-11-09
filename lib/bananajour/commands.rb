module Bananajour::Commands

  def check_git!
    if (version = `git --version`.strip) =~ /git version 1\.[12345]/
      abort "You have #{version}, you need at least 1.6"
    end
  end

  def check_git_config!
    config_message = lambda {|key, example| "You haven't set your #{key} in your git config yet. To set it: git config --global #{key} '#{example}'"}
    abort(config_message["user.name", "My Name"]) if config.name.empty?
    abort(config_message["user.email", "name@domain.com"]) if config.email.empty?
  end

  def serve_web!
    pid = fork { exec "/usr/bin/env ruby #{File.dirname(__FILE__)}/../../#{Bananajour.big? ? "sinatra_big" : "sinatra"}/app.rb -p #{web_port} -e production" }
    puts "* Started " + web_uri.foreground(:yellow)
    pid
  end

  def serve_git!
    pid = fork { exec "git daemon --base-path=#{repositories_path} --export-all --port=#{git_port}" }
    puts "* Started " + "#{git_uri}".foreground(:yellow)
    pid
  end

  def advertise!
    pid = fork { Bananajour::Bonjour::Advertiser.new.go! }
    pid
  end

  def eat_me_some_bananas!
    pid = fork { Bananajour::Eater.new.go! }
    pid
  end

  def add!(dir, name = nil)
    dir = Fancypath(dir)

    unless dir.join(".git").directory?
      abort "Can't init project #{dir}, no .git directory found."
    end

    if name.nil?
      default_name = dir.basename.to_s
      print "Project Name?".foreground(:yellow) + " [#{default_name}] "
      name = (STDIN.gets || "").strip
      name = default_name if name.empty?
    end

    repo = Bananajour::Repository.for_name(name)

    if repo.exists?
      abort "You've already a project #{repo}."
    end

    repo.init!
    Dir.chdir(dir) { `git remote add banana #{repo.path.expand_path}` }
    puts init_success_message(repo.dirname)

    repo
  end
  
  def init_success_message(repo_dirname)
    plain_init_success_message(repo_dirname).gsub("git push banana master", "git push banana master".foreground(:yellow))
  end
  
  def plain_init_success_message(repo_dirname)
    "Bananajour repository #{repo_dirname} initialised and remote banana added.\nNext: git push banana master"
  end
  
  def clone!(url, clone_name)
    dir = clone_name || File.basename(url).chomp('.git')

    if File.exists?(dir)
      abort "Can't clone #{url} to #{dir}, the directory already exists."
    end

    `git clone #{url} #{dir}`
    if $? != 0
      abort "Failed to clone bananajour repository #{url} to #{dir}."
    else
      puts "Bananajour repository #{url} cloned to #{dir}."
      add!(dir, dir)
    end
  end

end
