class Gitcycle < Thor

  desc "assist SUBCOMMAND", "Type `git cycle assist` to see subcommands"
  subcommand "assist", Subcommands::Assist
end