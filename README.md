Gitcycle
========

Enterprise development cycle platform.

Is this your dev cycle?
-----------------------

* Process is not followed the same way every time
* Process is not enforced strictly, mistakes happen
* Developers are wasting too much time in Git
* Developers are wasting too much time in ticketing software
* Its too cumbersome to write custom code around process

Maybe Gitcycle can help
-----------------------

* Codifies process (pull request -> code review -> qa)
* Non-intrusive `git` wrapper for developers
* HTTP server for recording events and executing custom code
* Pre-baked support for Github and/or Lighthouse

Install Gem
-----------

	gem install gitcycle

Start Server
------------

You need to have a [gitcycle_api](https://github.com/winton/gitcycle_api2) web server running.

Please visit the project page for installation instructions.

If you question the idea of needing a server, please read [Why a server?](https://github.com/winton/gitcycle/wiki/Why-a-server%3F).

Setup Client
------------

Visit your running [gitcycle_api](https://github.com/winton/gitcycle_api2) web server via browser.

Login and follow the instructions on the setup tab.

Create Git Aliases
------------------

Run gitcycle commands like so:

	git cycle [COMMAND]

Since gitcycle does not have command names that conflict with standard `git` commands, you can alias them like so:

	git cycle alias

Now you can run `git [COMMAND]` for all gitcycle commands.

The rest of the README assumes you have aliased your gitcycle commands.

Track a Branch
--------------

Gitcycle provides a shortcut for easily checking out branches.

The shortcut is smart enough to pick the right branch to checkout, whether it be from your repo or upstream.

It "just works" to checkout a branch from your fork or upstream repo like this:

	git track [BRANCH]

To collaborate with another user:
	
	git track [REMOTE]/[BRANCH]

Create a Feature Branch
-----------------------

First, `track` the branch that you want your feature branch to eventually merge into (for example, a release candidate branch):

	git track rc

Now let's create a feature branch from one of the following options:

### Github Issue

	git feature https://github.com/user/repo/issues/0000

### Lighthouse Ticket

	git feature https://xxx.lighthouseapp.com/projects/0000/tickets/0000-my-ticket

### Title

You can create an issue and feature branch at once!

	git feature "This is my issue title"

Sync Branch
-----------

Push and pull changes to and from your repo and the upstream repo with a single command:

	git sync

You should rarely need to use `git pull` or `git push` (but you still can if you want to :).

Commit
------

Commit like always via `git commit`. Gitcycle populates your commit message with issue information.

Create Pull Request
-------------------

After syncing some commits, create a pull request to discuss your code:

	git pr

Ready for Code Review
---------------------

When the branch is ready for code review:

	git ready

Code Review
-----------

### Pass

	git review pass [GITHUB ISSUE #] [...]

Now this feature is ready for QA.

### Fail

	git review fail [GITHUB ISSUE #] [...]

Once the problem is resolved, the committer should run `git ready` on the feature branch again.

Quality Assurance
-----------------

### Create QA Branch

	git qa [GITHUB ISSUE #] [...]

This generates a QA branch containing all commits from the specified Github issue numbers.

### Fail

	git qa fail [GITHUB ISSUE #]

### Pass

	git qa pass

This merges the QA branch into the target branch.

### Immediate Pass

	git qa pass [GITHUB ISSUE #] [...]

This immediately merges issues into the target branch without generating a QA branch first.

More Magic!
-----------

A lot more happens when you run the commands above, such as issue labeling and state changing.

Gitcycle also has some more add-ons not described here. To see them:

	git cycle -h