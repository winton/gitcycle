Feature: Push

Scenario: Collaborator
  Given a fresh set of repositories
  When I cd to the owner repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
    And I cd to the user repo
    And I execute gitcycle with "co config.owner/master-ticket.id"
    And gitcycle runs
    And I commit something
    And I execute gitcycle with "push"
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Fetching remote 'config.owner'.
    Merging remote branch 'master-ticket.id' from 'config.owner/config.repo'.
    Pushing branch 'config.owner/master-ticket.id'.
    """
    And current branch is "master-ticket.id"