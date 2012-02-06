Gitcycle
========

Gitcycle is a wrapper for git that makes working on a team easy.

By default, Gitcycle assumes you are working on a fork-based development cycle along side [GitHub Issues](https://github.com/features/projects/issues).

Gitcycle also connects to email, Lighthouse, and Campfire if you want it to.

Get Started
-----------

Visit [gitcycle.com](http://gitcycle.com) to set up your repository.

Drop-In Replacement
-------------------

The `gitc` command responds to everything `git` does, but adds some extra features.

The idea, at least, is that you can completely drop `git` in favor of `gitc`.

Create Branch From Ticket
-------------------------

First, checkout the branch that you will eventually merge your code into.

Type `gitc branch` + your ticket URL to create a new branch:

	gitc branch https://xxx.lighthouseapp.com/projects/0000/tickets/0000-my-ticket

Pull Changes
------------

Use `gitc pull` without parameters. It will know what you're trying to do.

	gitc pull

If you're working on a ticket branch, it will automatically pull the latest code from upstream.

Commit Code
-----------

Commit all changes and open commit message in EDITOR with ticket info prefilled:

	gitc commit

Push Changes
------------

Use `gitc push` without parameters. It will know what you're trying to do.

	gitc push

Discuss Code
------------

After pushing one or two commits, put the code up for discussion:

	gitc discuss

Mark as Ready
-------------

When the branch is ready for merging, mark it as ready:

	gitc ready

This will mark the pull request as "Pending Review".

Code Review
-----------

Managers will periodically check for "Pending Review" issues on GitHub.

Once reviewed, they will mark the issue as reviewed:

	gitc reviewed [GITHUB ISSUE #] [...]

Quality Assurance
-----------------

QA engineers will periodically check for "Pending QA" issues on Github.

To create a new QA branch:

	gitc qa [GITHUB ISSUE #] [...]

This will create a new QA branch containing the commits from the related Github issue numbers.

This branch can be deployed to a staging environment for QA.

QA Fail
-------

If a feature does not pass QA:

	gitc qa fail [GITHUB ISSUE #] [...]

To fail all issues:

	gitc qa fail

This will add a "fail" label to the issue.

QA Pass
------- 

If a feature passes QA:

	gitc qa pass [GITHUB ISSUE #] [...]

To pass all issues:

	gitc qa pass

This will add a "pass" label to the issue and will complete the pull request by merging the feature branch into the target branch.

More
----

### Checkout Upstream Branch

If you are working in a fork, it is easy to checkout upstream branches:

	gitc checkout [BRANCH]

### Collaborate

Checkout branches from other forks:

	gitc checkout [USER] [BRANCH]

### QA Status

See who is QA'ing what:

	gitc qa

### Redo Branch

If you associate the wrong branch with a ticket, use `gitc redo` to fix it.

	gitc redo https://xxx.lighthouseapp.com/projects/0000/tickets/0000-my-ticket

Todo
----

* Add ability to associate multiple branches/pull requests with one Lighthouse ticket
* Add comment on lighthouse with issue URL
* gitc discuss should tag issue with 'Discuss'
* On pass or fail, send email to Github email
* Note you can use gitc with a string
* gitc qa pass, should not set ticket to pending-approval if its already resolved
* If gitc reset happens on branch with Github issue, close the existing issue
* Add comment on lighthouse with issue URL
* Instead of detecting CONFLICT, use error status $? != 0
* Label issues with ticket milestone
* gitc qa pass # since we're changing this to pass all the tickets, we need to loop through all the merged issues and update the lighthouse state to pending-qa
* There's still a Tagging Issue I tried to fix parseLabel http://d.pr/8eOS , Pass should remove Pending, but remove the Branch Name
* gitc ready - possibly do syntax checks