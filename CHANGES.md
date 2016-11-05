0.4.0 - 2016/11/05

1. **big change:** the server client chain provides `serverClient` property instead of `connection` which seems to be a much better name because the others are `client` and `server`, and, the function to add listeners for it is `onServerClient()`.
2. `cio` constructor no longer builds all three chains. That's a waste because it's unlikely someone will be using both client and server chains at the same time because we usually build clients and servers separately. So, it now builds a chain only when someone wants to add a listener to it or run it.
3. separated parts of building a chain so it can be overridden to alter how they're made
4. made non-private functions which get the specific chains (and builds them if they're not yet). I'm unsure if I really want them public or private. I can see reasons for both ways. Normally, I prefer private functions. I decided on going for public because I am using one in the `emit-new-server-client` listener. So, that says to me, if it's helpful in one listener, it may be helpful in other listeners. We'll see how it turns out.


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
