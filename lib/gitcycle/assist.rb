class Gitcycle < Thor

  desc "assist <subcommand>", "Type `git cycle assist` for subcommands"
  subcommand "assist", Subcommands::Assist
end