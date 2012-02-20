Feature: Discuss

Scenario: Discuss commits w/ no parameters and nothing committed
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And I execute gitcycle with "discuss"
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Creating GitHub pull request.
    You must push code before opening a pull request.
    """
    And redis entries valid

Scenario: Discuss commits w/ no parameters and something committed
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
    And I commit something
    And I execute gitcycle with "discuss"
    And gitcycle runs
  Then output includes
      """
      Retrieving branch information from gitcycle.
      Creating GitHub pull request.
      Labeling issue as 'Discuss'.
      """
    And output includes "Opening issue" with URL
    And URL is a valid issue
    And redis entries valid

Scenario: Discuss commits w/ parameters
  When I cd to the user repo
    And I execute gitcycle with "discuss issue.id"
    And gitcycle runs
  Then output includes "Retrieving branch information from gitcycle."
    And output does not include "Creating GitHub pull request."
    And output does not include "Branch not found."
    And output does not include "You must push code before opening a pull request."
    And output includes "Opening issue" with URL
    And URL is a valid issue