Feature: gitcycle

Scenario: No command given
  When I execute gitcycle with nothing
  Then gitcycle runs
    And output includes "No command specified"

Scenario: Non-existent command
  When I execute gitcycle with "blah blah"
  Then gitcycle runs
    And output includes "Command 'blah' not found"

Scenario: Setup
  When I execute gitcycle setup
  Then gitcycle runs
    And output includes "Configuration saved."
    And gitcycle.yml should be valid

Scenario: Feature branch w/ custom branch name
  Given a fresh set of repositories
    And a new Lighthouse ticket
  When I cd to the user repo
    And I execute gitcycle with the Lighthouse ticket URL
    And I enter "y"
    And I enter "n"
    And I enter "ticket.id-rename"
  Then gitcycle runs
    And output includes
      """
      Retrieving branch information from gitcycle.
      Your work will eventually merge into 'master'. Is this correct? (y/n)
      Adding remote repo 'br/gitcycle_test'.
      Fetching remote repo 'br'.
      Checking out remote branch 'master' from 'br/gitcycle_test'.
      Would you like to name your branch 'ticket.id'? (y/n)
      What would you like to name your branch?
      Creating 'ticket.id-rename' from 'master'.
      Checking out branch 'ticket.id-rename'.
      Pushing 'ticket.id-rename'.
      Sending branch information to gitcycle.
      """
    And redis entries valid

Scenario: Feature branch
  Given a fresh set of repositories
    And a new Lighthouse ticket
  When I cd to the user repo
    And I execute gitcycle with the Lighthouse ticket URL
    And I enter "y"
    And I enter "y"
  Then gitcycle runs
    And output includes "Retrieving branch information from gitcycle."
    And output includes "Your work will eventually merge into 'master'. Is this correct?"
    And output includes "Would you like to name your branch 'ticket.id'?"
    And output does not include "What would you like to name your branch?"
    And output includes "Creating 'ticket.id' from 'master'."
    And output includes "Checking out branch 'ticket.id'."
    And output includes "Pushing 'ticket.id'."
    And output includes "Sending branch information to gitcycle."
    And redis entries valid

Scenario: Checkout via ticket w/ existing branch
  When I cd to the user repo
    And I execute gitcycle with the Lighthouse ticket URL
  Then gitcycle runs
    And output includes "Retrieving branch information from gitcycle."
    And output does not include "Would you like to name your branch 'ticket.id'?"
    And output does not include "What would you like to name your branch?"
    And output does not include "Creating 'ticket.id' from 'master'."
    And output includes "Checking out branch 'ticket.id'."
    And output does not include "Pushing 'ticket.id'."
    And output does not include "Sending branch information to gitcycle."
    And current branch is "ticket.id"

Scenario: Checkout via ticket w/ fresh repo
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle with the Lighthouse ticket URL
  Then gitcycle runs
    And output includes "Retrieving branch information from gitcycle."
    And output does not include "Would you like to name your branch 'ticket.id'?"
    And output does not include "What would you like to name your branch?"
    And output does not include "Creating 'ticket.id' from 'master'."
    And output includes "Tracking branch 'ticket.id'."
    And output does not include "Pushing 'ticket.id'."
    And output does not include "Sending branch information to gitcycle."
    And current branch is "ticket.id"

Scenario: Pull changes from upstream
  When I cd to the owner repo
    And I checkout master
    And I commit something
    And I cd to the user repo
    And I checkout ticket.id
    And I execute gitcycle with "pull"
  Then gitcycle runs
    And output includes "Retrieving branch information from gitcycle."
    And output includes "Adding remote repo 'config.owner/config.repo'."
    And output includes "Fetching remote repo 'config.owner'."
    And output includes "Merging remote branch 'master' from 'config.owner/config.repo'."
    And git log should contain the last commit

Scenario: Discuss commits w/ no parameters and nothing committed
  When I cd to the user repo
    And I checkout ticket.id
    And I execute gitcycle with "discuss"
  Then gitcycle runs
    And output includes "Retrieving branch information from gitcycle."
    And output includes "Creating GitHub pull request."
    And output does not include "Branch not found."
    And output does not include "Opening issue"
    And output includes "You must push code before opening a pull request."
    And redis entries valid

Scenario: Discuss commits w/ no parameters and something committed
  When I cd to the user repo
    And I checkout ticket.id
    And I commit something
    And I execute gitcycle with "discuss"
  Then gitcycle runs
    And output includes "Retrieving branch information from gitcycle."
    And output includes "Creating GitHub pull request."
    And output does not include "Branch not found."
    And output includes "Opening issue" with URL
    And output does not include "You must push code before opening a pull request."
    And URL is a valid issue
    And redis entries valid

Scenario: Discuss commits w/ parameters
  When I cd to the user repo
    And I checkout ticket.id
    And I execute gitcycle with "discuss issue.id"
  Then gitcycle runs
    And output includes "Retrieving branch information from gitcycle."
    And output does not include "Creating GitHub pull request."
    And output does not include "Branch not found."
    And output does not include "You must push code before opening a pull request."
    And output includes "Opening issue" with URL
    And URL is a valid issue

Scenario: Ready issue w/ no parameters
  When I cd to the user repo
    And I checkout ticket.id
    And I execute gitcycle with "ready"
  Then gitcycle runs
    And output includes "Labeling issue as 'Pending Review'."

Scenario: Ready issue w/ parameters
  When I cd to the user repo
    And I execute gitcycle with "ready issue.id"
  Then gitcycle runs
    And output includes "Labeling issues as 'Pending Review'."

Scenario: Reviewed issue w/ no parameters
  When I cd to the user repo
    And I checkout ticket.id
    And I execute gitcycle with "reviewed"
  Then gitcycle runs
    And output includes "Labeling issue as 'Pending QA'."

Scenario: Reviewed issue w/ parameters
  When I cd to the user repo
    And I execute gitcycle with "reviewed issue.id"
  Then gitcycle runs
    And output includes "Labeling issues as 'Pending QA'."

Scenario: QA issue
  When I cd to the owner repo
    And I checkout master
    And I execute gitcycle with "qa issue.id"
  Then gitcycle runs
    And output includes
      """
      Retrieving branch information from gitcycle.
      Deleting old QA branch 'qa_master'.
      Creating QA branch 'qa_master'.
      Adding remote repo 'config.user/gitcycle_test'.
      Fetching remote repo 'config.user'.
      Merging remote branch 'ticket.id' from 'config.user/gitcycle_test'.
      Pushing QA branch 'qa_master'.
      Type 'gitc qa pass' to approve all issues in this branch.
      Type 'gitc qa fail' to reject all issues in this branch.
      """