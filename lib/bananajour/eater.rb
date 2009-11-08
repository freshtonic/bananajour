class Bananajour::Eater
  def initialize
    @browser = Bananajour::Bonjour::RepositoryBrowser.new
  end
  def go!
    while true do
      @browser.repositories.each do |remote_repo|
        local_repo_name = make_local_repo_name(remote_repo)
        repo = Bananajour::Repository.for_name local_repo_name
        if !remote_repo.ismirror 
          if repo.exists?
            $stderr.puts "fetching changes from: #{remote_repo.uri} to #{local_repo_name}"
            `cd #{repo.path} && git fetch origin`
          else
            $stderr.puts "cloning remote repo #{remote_repo.uri} to #{local_repo_name}"
            `cd #{Bananajour.repositories_path} && git clone --bare #{remote_repo.uri} #{local_repo_name}.git && cd #{local_repo_name}.git && git remote add origin #{remote_repo.uri}`
          end
        end
      end
      sleep 30
    end
  end
  private
  def make_local_repo_name(remote_repo)
    sanitize_email(remote_repo.person.email) + "" + remote_repo.name
  end
  def sanitize_email(email)
    # we're going to end up using the email address as part of a directory
    # name, so we better make sure it can be represented on the filesystem.
    email.gsub(/@/, "_at_").gsub(/\./, "_dot_").gsub(/[^A-Za-z0-9\._-]/, "")
  end
end
