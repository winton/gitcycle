class Gitcycle < Thor

  desc "assist", "list assistance requests"
  def assist
  end

  class Subcommands < Thor

    desc "assign <request #> <user>", "assign assistance request to user"
    def assign
    end

    desc "cancel", "give up any assistance requests you have taken responsibility for"
    def cancel
    end

    desc "complete", "complete any assistance requests you have taken responsibility for"
    def complete
    end

    desc "me", "ask for assistance"
    def me
    end

    desc "take <request #>", "take responsibility for assistance request"
    def take
    end
  end

  subcommand "assist", Subcommands
end