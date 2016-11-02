
0.3.0 - Released 2016/11/02

1. changed internals to use `chain-builder` for socket type specific work chains.
2. revise core listeners to be members of a chain
3. add core listeners into work chains with ID's so they can be disabled, removed, or new workers ordered around them
4. add helper functions which accept listeners for specific socket types and add them to the correct work chain
5. helper functions accept strings which are given to `require()` to load the module
6. included relistener style from 'plugins' branch
7. adapted test suite from 'plugins' branch
8. updated README for these changes (lots of TODO spots left though)


0.2.0 - 0.2.1 - Removing this "plugins" style. (Decided I disliked it.)

0.1.0 - Unreleased

1. initial working version **without** tests
