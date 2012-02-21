Feature: Setup

Scenario: Setup
  When I execute gitcycle setup
  	And gitcycle runs
  Then output includes "Configuration saved."
    And gitcycle.yml should be valid