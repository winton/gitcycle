# Feature: gitcycle

# Scenario: Reviewed issue w/ no parameters
#   When I cd to the user repo
#     And I checkout ticket.id
#     And I execute gitcycle with "review pass"
#   Then gitcycle runs
#     And output includes "Labeling issue as 'Pending QA'."

# Scenario: Reviewed issue w/ parameters
#   When I cd to the user repo
#     And I execute gitcycle with "review pass issue.id"
#   Then gitcycle runs
#     And output includes "Labeling issues as 'Pending QA'."

# Scenario: QA issue
#   When I cd to the owner repo
#     And I checkout master
#     And I execute gitcycle with "qa issue.id"
#     And I enter "y"
#   Then gitcycle runs
#     And output includes
#       """
#       Do you want to create a QA branch from 'master'? (y/n)
#       Retrieving branch information from gitcycle.
#       Deleting old QA branch 'qa_master_config.user'.
#       Adding remote repo 'config.owner/config.repo'.
#       Fetching remote 'config.owner'.
#       Checking out remote branch 'qa_master_config.user' from 'config.owner/config.repo/master'.
#       Fetching remote 'origin'.
#       Pushing 'origin/qa_master_config.user'.
#       Adding remote repo 'config.user/config.repo'.
#       Fetching remote 'config.user'.
#       Merging remote branch 'ticket.id' from 'config.user/config.repo'.
#       Pushing branch 'qa_master_config.user'.
#       Type 'gitc qa pass' to approve all issues in this branch.
#       Type 'gitc qa fail' to reject all issues in this branch.
#       """

# Scenario: QA issue pass
#   When I cd to the owner repo
#     And I checkout qa_master_config.user
#     And I execute gitcycle with "qa pass"
#   Then gitcycle runs
#     And output includes
#       """
#       Retrieving branch information from gitcycle.
#       Checking out branch 'master'.
#       Adding remote repo 'config.user/config.repo'.
#       Fetching remote 'config.user'.
#       Merging remote branch 'ticket.id' from 'config.user/config.repo'.
#       Pushing branch 'master'.
#       Labeling all issues as 'Pass'.
#       """

# Scenario: QA issue list
#   When I cd to the owner repo
#     And I checkout master
#     And I execute gitcycle with "qa"
#   Then gitcycle runs
#     And output includes
#       """
#       qa_master_config.user
#         issue #issue.id\tconfig.user/ticket.id
#       """