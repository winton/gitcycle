Gitcycle
========

Tame your development cycle.

About
-----

Gitcycle is a `git` wrapper that makes working on a team easy.

It assumes you are using pull requests along side [GitHub Issues](https://github.com/features/projects/issues).

It connects to email, Lighthouse, and Campfire if you want it to.

Get Started
-----------

Visit [gitcycle.com](http://gitcycle.com) to set up your repository.

gitc
----

The `gitc` command does everything `git` does, but with some extra features.

Try using `gitc` for everything. It should just work.

Branch From Ticket
------------------

First, checkout the branch that you will eventually merge your code into:

	gitc checkout [BRANCH]

Type `gitc branch` + your ticket URL to create a new branch:

	gitc branch https://xxx.lighthouseapp.com/projects/0000/tickets/0000-my-ticket

Pull
----

Use `gitc pull` without parameters. It knows what you're trying to do.

	gitc pull

If you're working on a ticket branch, it will automatically pull the latest code from upstream.

Commit
------

Commit all changes and open commit message in EDITOR:

	gitc commit

Ticket number and name are prefilled if present.

Push
----

Use `gitc push` without parameters. It knows what you're trying to do.

	gitc push

Discuss
-------

After pushing some commits, put the code up for discussion:

	gitc discuss

Ready
-----

When the branch is ready for code review:

	gitc ready

This will label the pull request as "Pending Review".

Code Review
-----------

Periodically check for "Pending Review" issues on GitHub.

### Pass

	gitc review pass [GITHUB ISSUE #] [...]

Label the issue "Pending QA".

### Fail

	gitc review fail [GITHUB ISSUE #] [...]

Label the issue "Fail".

Quality Assurance
-----------------

Periodically check for "Pending QA" issues on Github.

### Create QA Branch

	gitc qa [GITHUB ISSUE #] [...]

Now you have a QA branch containing all commits from the specified Github issue numbers.

### Fail

	gitc qa fail [GITHUB ISSUE #]

Label the issue with "Fail" and regenerate the QA branch without the failing issue.

### Pass

	gitc qa pass

Label all issues "Pass" and the merge the QA branch into target branch.

### Immediate Pass

	gitc checkout [TARGET BRANCH]
	gitc qa pass [GITHUB ISSUE #] [...]

Immediately merge issue into the target branch.

### Status

See who is QA'ing what:

	gitc qa

Checkout
--------

Check out an upstream or local branch:

	gitc checkout [BRANCH]

### From Ticket

Checkout a branch from a ticket URL:

	gitc checkout [TICKET URL]

### From User's Fork

	gitc checkout user/branch

Todo
----

Nice to haves:
* gitc branch [lh]
* gitc branch [gitissue]
* gitc ready # switch me back to rc or master
* gitc ready - issue already closed, will open a new issue

* Conflict recording not working
* gitc qa pass [issue] should use a qa_rc_tongueroo_temp branch so it doesnt blow away the changes in the qa_rc_tongueroo branch
	* not working : https://gist.github.com/819c99281f5d6492de47
* gitc qa pass (all), doesnt update lighthouse to state pending-approval 
* Collaborator mode = work on same ticket, gitc ready readys ticket no matter who is working on it, if more than one ticket then we should have a feature branch that people are basing tickets off of
* Hook to run after gitc qa pass, so I can write a script for amit that will auto merge master into rc
* Issues aren't assigned to people
* On pass or fail, send email to Github email
* Note you can use gitc with a string (and get this working)
* gitc qa pass, should not set ticket to pending-approval if its already resolved
* Everything before colon in ticket name, make shorter somehow
$ gitc st - shortcut
* gitc clean # to clean up old branches
* fail should change to inactive
* gitc pull: shouldnt matter who does it, it should update the latest br/rc, not working https://gist.github.com/22b1e248e8dba7a32288