Feature: Checkout

Scenario: Existing branch
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle branch with a new URL or string
    And I give default input
    And I execute gitcycle checkout with the last URL or string
    And gitcycle runs
  Then output includes
    """
    Retrieving branch information from gitcycle.
    Checking out branch 'ticket.id'.
    """
    And current branch is "ticket.id"

Scenario: Fresh repo
  Given a fresh set of repositories
  When I cd to the user repo
    And I execute gitcycle checkout with the last URL or string
  Then gitcycle runs
    And output includes
      """
      Retrieving branch information from gitcycle.
      Tracking branch 'origin/last_ticket.id'.
      """
    And current branch is "last_ticket.id"