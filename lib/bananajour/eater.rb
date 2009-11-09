class Bananajour::Eater
  def initialize
    @browser = Bananajour::Bonjour::RepositoryBrowser.new
  end
  def go!
    while true do
      @browser.repositories.each do |remote_repo|
        repo = Bananajour::Repository.for_name remote_repo.name
        unless remote_repo.ismirror 
          remote_name = make_remote_name(remote_repo.person.email)
          if repo.exists?
            link_to_remote(repo, remote_repo, remote_name) unless repo.grit_repo.remotes.select{|r| r.name =~ Regexp.new("^#{remote_name}")}.size > 0
            fetch_remote(repo, remote_name)
          else
            clone_repo(remote_repo, remote_repo.name)
            link_to_remote(repo, remote_repo, remote_name) 
            fetch_remote(repo, remote_name)
          end
        end
      end
      sleep 30
    end
  end
  private
  def make_remote_name(email)
    # Use the email address as the remote name.
    # We need to mangle it to make sure it's a valid remote name though.
    # NOTE: this is probably too pessimistic, and will probably piss of people with
    # none ASCII-range characters in their email address.  Good enough for now.
    email.gsub(/@/, "_at_").gsub(/\./, "_dot_").gsub(/[^A-Za-z0-9\._-]/, "")
  end
  # Creates a remote in repo that points to remote_repo.
  # The name of the remote will be the mangled email address of the remote_repo's creator.
  def link_to_remote(repo, remote_repo, remote_name)
    `cd #{repo.path} && git remote add #{remote_name} #{remote_repo.uri}`
  end
  def fetch_remote(repo, remote_name)
    # Grit doesn't do fetching(!) so, we'll invoke this ourselves.
    `cd #{repo.path} && git fetch #{remote_name}`
  end
  def clone_repo(remote_repo, local_repo_name)
    `cd #{Bananajour.repositories_path} && git clone --bare #{remote_repo.uri} #{local_repo_name}.git`
  end
end
