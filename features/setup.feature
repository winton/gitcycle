Feature: Setup

# Scenario: Setup
#   When I execute gitcycle setup
#     And gitcycle runs
#   Then output includes "Configuration saved."
#     And gitcycle.yml should be valid

Scenario: Gitcycle command on non-repo
  When I cd to a non-repo
    And I execute gitcycle with "pull"
    And gitcycle runs
  Then gitcycle exits
    And output includes
      """
      You are not in a git repository.
      """

Scenario: Gitcycle command on repo with invalid origin
  When I cd to a non-repo
    And I run "git init ."
    And I execute gitcycle with "pull"
    And gitcycle runs
  Then gitcycle exits
    And output includes
      """
      Please make sure you have a valid 'origin' remote.
      See http://gitref.org/remotes
      """

Scenario: Gitcycle command on repo with unauthenticated user
  When I cd to a non-repo
    And I run "git init ."
    And I run "git remote add origin git@github.com:winton/gitcycle_test.git"
    And I execute gitcycle with "pull"
    And I enter "blah"
    And gitcycle runs
  Then gitcycle exits
    And output includes
      """
      What is your github username?
      Please set up gitcycle for 'blah' at gitcycle.com/setup
      """
    And open "http://gitcycle.com/setup" in browser

Scenario: Gitcycle command on repo with authenticated user
  When I cd to a non-repo
    And I run "git init ."
    And I run "git remote add origin git@github.com:winton/gitcycle_test.git"
    And I execute gitcycle with "pull"
    And I enter "config.user"
    And I enter "config.lighthouse_token"
    And gitcycle runs
  Then output includes
    """
    What is your github username?
    Configuration saved.
    Retrieving repo information from gitcycle.
    What is your Lighthouse API token?
    Gitcycle could not determine the branch you are on.
    """