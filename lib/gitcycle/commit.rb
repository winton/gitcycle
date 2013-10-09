class Gitcycle < Thor

  desc "commit", "Commit with ticket information in message"
  option :'no-add', :type => :boolean

  def commit
    msg = nil

    require_git && require_config

    puts "\nRetrieving branch information from gitcycle.\n".green
    branch = get('branch',
      'branch[name]' => branches(:current => true),
      'create' => 0
    )

    id = branch["lighthouse_url"].match(/tickets\/(\d+)/)[1] rescue nil

    if branch && id
      msg = "[##{id}]"
      msg += " #{branch["title"]}" if branch["title"]
    end

    if options[:no_add]
      cmd = "git commit"
    else
      cmd = "git add . && git add . -u && git commit -a"
    end

    if File.exists?("#{Dir.pwd}/.git/MERGE_HEAD")
      Kernel.exec(cmd)
    elsif msg
      run(cmd + " -m #{msg.dump.gsub('`', "'")}")
      Kernel.exec("git commit --amend")
    elsif args.empty?
      Kernel.exec(cmd)
    end
  end

  desc "ci", "Alias for commit", :hide => true
  alias :ci :commit
end