class Bananajour::Eater
  def initialize
    @browser = Bananajour::Bonjour::RepositoryBrowser.new
  end
  def go!
    while true do
      @browser.repositories.each do |remote_repo|
        # if we have a clone of the repo
        #   fetch the latest changes
        # else
        #   clone it
        repo = Repository.for_name remote_repo.name
        if repo.exists?

        else
          clone(remote_repo)
        end
      end
      sleep 30
    end
  end
end
