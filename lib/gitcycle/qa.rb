class Gitcycle < Thor

  desc "qa SUBCOMMAND", "Type `git cycle qa` to see subcommands"
  subcommand "qa", Subcommands::Qa
end