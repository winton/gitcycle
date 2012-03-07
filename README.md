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

To collaborate with another user, use a full path when prompted:

	Q: What branch would you like to eventually merge into?
	A: user/branch

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

### From Ticket

Checkout a branch from a ticket URL:

	gitc checkout [TICKET URL]

### Upstream Branch

Gitcycle automatically knows if you are checking out an upstream branch:

	gitc checkout [BRANCH]

Todo
----

* Conflict recording not working
* gitc qa pass [issue] should use a qa_rc_tongueroo_temp branch so it doesnt blow away the changes in the qa_rc_tongueroo branch
	* not working : https://gist.github.com/819c99281f5d6492de47
* gitc qa pass (all), doesnt update lighthouse to state pending-approval 
* Add comment on lighthouse with issue URL
* Multiple issues with one lighthouse tickets, wont update lh states
* Collab fork should change gitc ready to auo merge to the parent fork.  gitc pull should pull from br and parent fork.  gitc push should push to your same fork.
	Lighthouse ticket changes to pending-qa if ticket is not the same as the parent.
* gitc pull is not merging in br/rc 
* gitc push # when I'm a 'Both' person pushs to origin which is br, I still feel this should push to the fork directly.  Example here: https://gist.github.com/955f5b549d8d9ae1043a
* Hook to run after gitc qa pass, so I can write a script for amit that will auto merge master into rc
* gitc merge chrisped/branch-with-reverts # to quickly revert changes
* Label issues with ticket milestone
* Issues aren't assigned to people
* Add comment on lighthouse with issue URL
* On pass or fail, send email to Github email
* Note you can use gitc with a string (and get this working)
* gitc qa pass, should not set ticket to pending-approval if its already resolved
* If gitc redo happens on branch with Github issue, close the existing issue
* Instead of detecting CONFLICT, use error status $? != 0
* gitc ready - possibly do syntax checks
$ gitc st - shortcut
* issues aren't assigned to people
* There's still a Tagging Issue I tried to fix parseLabel http://d.pr/8eOS , Pass should remove Pending, but remove the Branch Name
* gitc qa pass 1234 # doesnt update lighthouse and screws up git issue tags
* [issue number] it marks it pending-qa and failed.. not correct.  I'll take a look at this over the weekend -Tung
* gitc qa clean # to clean up old branches
* gitc qa pass # if ticket resolved, it should stay resolved
* gitc ready # if pull requests already created, it should prompt and explain that a new branch and issue is being created, consider effect of multiple developers
* fail should change to inactive
* If feature branch changed between QA branch creation and QA merge, alert QA engineer