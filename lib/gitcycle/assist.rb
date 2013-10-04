class Gitcycle
  module Assist

    def assist(*args)
      if args.first == 'me'
      elsif args.first == 'complete'
      elsif args.first == 'cancel'
      else
        user      = args[0]
        assign_to = args[1]
      end
    end
  end
end