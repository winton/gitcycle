Feature: Branch

Scenario: Yes to all (easiest route)
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
  Then output includes
    """
    Your work will eventually merge into 'master'. Is this correct? (y/n)
    Retrieving branch information from gitcycle.
    Would you like to name your branch 'master-ticket.id'? (y/n)
    Adding remote repo 'config.owner/config.repo'.
    Fetching remote 'config.owner'.
    Checking out remote branch 'master-ticket.id' from 'config.owner/config.repo/master'.
    Fetching remote 'origin'.
    Pushing 'origin/master-ticket.id'.
    Sending branch information to gitcycle.
    """
    And redis entries valid

Scenario: Custom branch name
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I enter "y"
    And I enter "n"
    And I enter "master-ticket.id-rename"
    And gitcycle runs
  Then output includes
    """
    Your work will eventually merge into 'master'. Is this correct? (y/n)
    Retrieving branch information from gitcycle.
    Would you like to name your branch 'master-ticket.id'? (y/n)
    What would you like to name your branch?
    Adding remote repo 'config.owner/config.repo'.
    Fetching remote 'config.owner'.
    Checking out remote branch 'master-ticket.id-rename' from 'config.owner/config.repo/master'.
    Fetching remote 'origin'.
    Pushing 'origin/master-ticket.id-rename'.
    Sending branch information to gitcycle.
    """
    And redis entries valid

Scenario: Change source branch
  Given a fresh set of repositories
  When I cd to the user repo
    And I create a new branch "some_branch"
    And I checkout some_branch
    And I execute gitcycle branch with a new URL or string
    And I enter "n"
    And I enter "master"
    And I enter "y"
    And gitcycle runs
  Then output includes
    """
    Your work will eventually merge into 'some_branch'. Is this correct? (y/n)
    What branch would you like to eventually merge into?
    Retrieving branch information from gitcycle.
    Would you like to name your branch 'master-ticket.id'? (y/n)
    Adding remote repo 'config.owner/config.repo'.
    Fetching remote 'config.owner'.
    Checking out remote branch 'master-ticket.id' from 'config.owner/config.repo/master'.
    Fetching remote 'origin'.
    Pushing 'origin/master-ticket.id'.
    Sending branch information to gitcycle.
    """
    And redis entries valid

Scenario: Collaborator
  Given a fresh set of repositories
  When I cd to the owner repo
    And I create a new branch "some_branch"
    And I checkout some_branch
    And I push some_branch
    And I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I enter "n"
    And I enter "config.owner/some_branch"
    And I enter "y"
    And gitcycle runs
  Then output includes
    """
    Your work will eventually merge into 'master'. Is this correct? (y/n)
    What branch would you like to eventually merge into?
    Retrieving branch information from gitcycle.
    Would you like to name your branch 'config.owner-some_branch-ticket.id'? (y/n)
    Adding remote repo 'config.owner/config.repo'.
    Fetching remote 'config.owner'.
    Checking out remote branch 'config.owner-some_branch-ticket.id' from 'config.owner/config.repo/some_branch'.
    Fetching remote 'origin'.
    Pushing 'origin/config.owner-some_branch-ticket.id'.
    Sending branch information to gitcycle.
    """
    And redis entries valid