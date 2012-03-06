Feature: Pull

Scenario: Pull changes from upstream
  Given a fresh set of repositories
  When I cd to the owner repo
    And I checkout master
    And I commit something
    And I cd to the user repo
    And I checkout master
    And I execute gitcycle with "pull"
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Retrieving repo information from gitcycle.
    Adding remote repo 'config.owner/config.repo'.
    Fetching remote 'config.owner'.
    Merging remote branch 'master' from 'config.owner/config.repo'.
    Adding remote repo 'config.user/config.repo'.
    Fetching remote 'config.user'.
    Merging remote branch 'master' from 'config.user/config.repo'.
    """
    And git log should contain the last commit