class Gitcycle < Thor

  desc "review SUBCOMMAND", "Type `git cycle review` to see subcommands"
  subcommand "review", Subcommands::Review
end