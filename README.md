Gitcycle
========

Tame your development cycle.

Get Started
-----------

Visit [gitcycle.com](http://gitcycle.com) to set up your environment.

Create Branch
-------------

Checkout the branch that you will eventually merge your feature into:

	git checkout master

Type `gitc` + your ticket URL to create a new branch:

	gitc https://xxx.lighthouseapp.com/projects/0000/tickets/0000-my-ticket


Pull Changes from Upstream
--------------------------

When you're developing, you may need to pull new changes from the upstream branch that you will eventually merge your feature into:

	gitc pull

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

### Reset Branch

If you associate the wrong branch with a ticket, use `gitc reset` to fix it.

Checkout the branch that you will eventually merge your feature into:

	git checkout master

Type `gitc reset` + your ticket URL to reset the branch:

	gitc reset https://xxx.lighthouseapp.com/projects/0000/tickets/0000-my-ticket

### Track Upstream Branch

If you are working in a fork, it is easy to track upstream branches:

	gitc track [BRANCH] [...]

Todo
----

* Fix git fatal error (related to pull?)
* On pass or fail, send email to Github email
* Change QA branch name to qa_login_branch
* Note you can use gitc with a string
* Tag issue with Lighthouse tags (if == backend or frontend)
* gitc qa pass, should not set ticket to pending-approval if its already resolved
* If gitc reset happens on branch with Github issue, close the existing issue
* Add comment on lighthouse with issue URL
* Instead of detecting CONFLICT, use error status $? != 0
* Label issues with ticket milestone?
* gitc LH-ticket should not created a redis record right away, what happens if someone control-c
* gitc -h or gitc help