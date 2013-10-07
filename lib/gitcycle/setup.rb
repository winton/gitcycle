class Gitcycle < Thor

  desc "setup SUBCOMMAND", "Type `git cycle setup` to see subcommands"
  subcommand "setup", Subcommands::Setup
end