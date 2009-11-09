class Bananajour::Eater
  def initialize
    @browser = Bananajour::Bonjour::RepositoryBrowser.new
  end
  def go!
    while true do
      @browser.repositories.each do |remote_repo|
        unless remote_repo.ismirror 
          local_repo = Bananajour::Repository.for_name(make_local_repo_name(remote_repo))
          if local_repo.exists?
            fetch_latest(local_repo)
          else
            clone_repo(remote_repo)
            fetch_latest(local_repo)
          end
        end
      end
      sleep 30
    end
  end
  private
  def fetch_latest(repo)
    # Grit doesn't do fetching(!) so, we'll invoke this ourselves.
    # Note: the repo's were created with git --mirror
    # This means that when when we do git fetch, it's actually updating the BRANCHES.
    # This is so that git clone will create remote refs in the cloned repo.
    `cd #{repo.path} && git fetch -f`
  end
  def clone_repo(remote_repo)
    # FYI: git clone --bare doesn't add the remote 'origin', need to do it manually.
    system(["cd #{Bananajour.repositories_path}",
    "(mkdir #{sanitize_email(remote_repo.person.email)} || true)",
    "git clone --mirror #{remote_repo.uri} #{make_local_repo_name(remote_repo)}.git"
    ].join(" && "))
  end
  def sanitize_email(email)
    email.gsub(/@/, "_at_").gsub(/\./, "_dot_")
  end
  def make_local_repo_name(remote_repo)
    sanitize_email(remote_repo.person.email) + "/" + remote_repo.name
  end
end
