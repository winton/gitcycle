Feature: Ready

Scenario: Ready issue
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
    And I commit something
    And I execute gitcycle with "ready"
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Fetching remote 'config.owner'.
    Merging remote branch 'master' from 'config.owner/config.repo'.
    Adding remote repo 'config.user/config.repo'.
    Fetching remote 'config.user'.
    Merging remote branch 'master-ticket.id' from 'config.user/config.repo'.
    Creating GitHub pull request.
    Labeling issue as 'Pending Review'.
    """
    And output includes "Opening issue" with URL
    And URL is a valid issue

Scenario: Reopen pull request
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
    And I commit something
    And I execute gitcycle with "ready"
    And gitcycle runs
    And I cd to the owner repo
    And I checkout master
    And I execute gitcycle with "qa pass issue.id"
    And I enter "y"
    And gitcycle runs
    And I wait for 5 seconds
    And I cd to the user repo
    And I checkout master-ticket.id
    And I commit something
    And I wait for 5 seconds
    And I execute gitcycle with "ready"
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Fetching remote 'config.owner'.
    Merging remote branch 'master' from 'config.owner/config.repo'.
    Fetching remote 'config.user'.
    Merging remote branch 'master-ticket.id' from 'config.user/config.repo'.
    Creating GitHub pull request.
    Labeling issue as 'Pending Review'.
    """
    And output includes "Opening issue" with URL
    And URL is a valid issue
    And URL is not the same as the last

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
    And I commit something
    And I execute gitcycle with "ready"
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Fetching remote 'config.owner'.
    Merging remote branch 'some_branch' from 'config.owner/gitcycle_test'.
    Pushing branch 'config.owner/some_branch'.
    """