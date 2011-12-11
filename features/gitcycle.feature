Feature: gitcycle

Scenario: No command given
  When I execute gitcycle with ""
  Then the output should contain "No command specified"

Scenario: Non-existent command
  When I execute gitcycle with "blah blah"
  Then the output should contain "Command 'blah' not found"

Scenario: Setup
  When I execute gitcycle setup
  Then the output should contain "Configuration saved."
    And gitcycle.yml should be valid

Scenario: Feature branch
  Given a fresh set of repositories
    And a new Lighthouse ticket
  When I cd to the user repo
    And I execute gitcycle with the Lighthouse ticket URL
    And I type "y\n"
  Then output includes "Retrieving branch information from gitcycle."
    And output includes "Would you like to name your branch 'ticket.id'?"
    And output includes "Creating 'ticket.id' from 'master'."
    And output includes "Checking out branch 'ticket.id'."
    And output includes "Pushing 'ticket.id'."
    And output includes "Sending branch information to gitcycle."