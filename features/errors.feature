Feature: Errors

Scenario: No command given
  When I execute gitcycle with nothing
    And gitcycle runs
  Then output includes "No command specified"

Scenario: Non-existent command
  When I execute gitcycle with "blah blah"
    And gitcycle runs
  Then output includes "Command not recognized."