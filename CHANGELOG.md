# 3.0.0

The package has been entirely rewritten using principles of the State Monad.
The functionalities have also been changed.
Now the user have a fine control of the method to use (trailing, leading, both)
for both debouncing and throttling.

------ Added modules - MINOR ------

    Control
    Control.Debounce
    Control.Throttle


------ Removed modules - MAJOR ------

    MsgControl


# 2.0.0

MAJOR changes:

* `Strategy` is not a type anymore but a function signature.
  This enables the removal of decision trees (which are often source of bugs).
  * `- type Strategy`
  * `+ type alias Strategy msg = MsgWrapper msg -> msg -> State msg -> (State msg, Cmd msg)`

* This implies a changement in `debouncing`, `throttling` and `update` type definitions.
  * `- debouncing : Time.Time -> MsgControl.Strategy`
  * `+ debouncing : Time.Time -> MsgControl.Strategy msg`

  * `- throttling : Time.Time -> MsgControl.Strategy`
  * `+ throttling : Time.Time -> MsgControl.Strategy msg`

  * `- update : MsgWrapper msg -> Strategy -> Msg msg -> State msg -> (State msg, Cmd msg)`
  * `+ update : MsgWrapper msg -> Strategy msg -> Msg msg -> State msg -> (State msg, Cmd msg)`


# 1.0.0

Requires Elm 0.18

* Initial release: enables debouncing and throttling of messages.
