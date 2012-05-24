Feature: Checkout

Scenario: Existing branch
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And I execute gitcycle checkout with the last URL or string
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Checking out branch 'master-ticket.id'.
    """
    And current branch is "master-ticket.id"

Scenario: Fresh repo
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle checkout with the last URL or string
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Tracking branch 'origin/master-last_ticket.id'.
    """
    And current branch is "master-last_ticket.id"

Scenario: Collaborator
  Given a fresh set of repositories
  When I cd to the owner repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
    And I cd to the user repo
    And I execute gitcycle with "co config.owner/master-ticket.id"
    And gitcycle runs
  Then output includes
    """
    Adding remote repo 'config.owner/config.repo'.
    Fetching remote 'config.owner'.
    Creating branch 'master-ticket.id' from 'br/master-ticket.id'.
    Sending branch information to gitcycle.
    Checking out 'master-ticket.id'.
    """
    And current branch is "master-ticket.id"