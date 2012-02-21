Feature: Review

Scenario: No parameters
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
    And I commit something
    And I execute gitcycle with "ready"
    And gitcycle runs
    And I execute gitcycle with "review pass"
    And gitcycle runs
  Then output includes "Labeling issue as 'Pending QA'."

Scenario: Parameters
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And gitcycle runs
    And I commit something
    And I execute gitcycle with "ready"
    And gitcycle runs
    And I execute gitcycle with "review pass issue.id"
    And gitcycle runs
  Then output includes "Labeling issues as 'Pending QA'."