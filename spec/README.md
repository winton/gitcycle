Run Specs
---------

(From root project directory)

    bundle
    rake spec

Testing Binary Manually
-----------------------

    CONFIG=../gitcycle.yml bin/git-cycle develop "this is a test"

TODOs
-----

* `:catch => true` by default on `run`
* `git track` collaboration