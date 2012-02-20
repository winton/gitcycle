Feature: Branch

Scenario: Yes to all (easiest route)
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
  Then output includes
      """
      Retrieving branch information from gitcycle.
      Your work will eventually merge into 'master'. Is this correct? (y/n)
      Would you like to name your branch 'ticket.id'? (y/n)
      Adding remote repo 'config.owner/config.repo'.
      Fetching remote 'config.owner'.
      Checking out remote branch 'ticket.id' from 'config.owner/config.repo/master'.
      Fetching remote 'origin'.
      Pushing 'origin/ticket.id'.
      Sending branch information to gitcycle.
      """
    And redis entries valid

Scenario: Custom branch name
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I enter "y"
    And I enter "n"
    And I enter "ticket.id-rename"
    And gitcycle runs
  Then output includes
      """
      Retrieving branch information from gitcycle.
      Your work will eventually merge into 'master'. Is this correct? (y/n)
      Would you like to name your branch 'ticket.id'? (y/n)
      What would you like to name your branch?
      Adding remote repo 'config.owner/config.repo'.
      Fetching remote 'config.owner'.
      Checking out remote branch 'ticket.id-rename' from 'config.owner/config.repo/master'.
      Fetching remote 'origin'.
      Pushing 'origin/ticket.id-rename'.
      Sending branch information to gitcycle.
      """
    And redis entries valid