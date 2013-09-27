class Gitcycle
  module Incident

    def incident(*args)
      puts "\nRetrieving statuspage.io information from gitcycle.\n".green
      statuspage = get('statuspage')
      puts statuspage.inspect
    end
  end
end