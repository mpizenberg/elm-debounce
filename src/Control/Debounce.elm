-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/


module Control.Debounce
    exposing
        ( leading
        , trailing
        , both
        )

{-| Debounce messages.

Debounced messages are grouped together.
Meaning if a message is emitted every second,
but with a debounced delay of 2s,
they will be all grouped together and only one
of these messages will be triggered.

Debouncing on leading edge will trigger the first message
of the group (so immediately) whereas trailing edge will
trigger the last of the group (later).

If the `both` strategy is selected, and the group of messages
contains at least 2 messages, both the first message (immediately)
and the last one (later) of the group will be triggered.

For complete minimalist examples,
please refer to the files:

* examples/DebounceTextTrailing.elm
* examples/DebounceButtonBoth.elm

@docs leading, trailing, both

-}

import Time exposing (Time)
import Control as Ctl exposing (State, Wrapper, Control)
import Control_ as Ctl
import StateMonad as SM
import Helpers as HP
import State


-- LEADING EDGE ######################################################


{-| Debounce on leading edge ("immediate").

    debounce : Msg -> Msg
    debounce = Control.Debounce.leading Deb (1 * Time.second)

    view model =
        button
            [ map debounce <| onClick Increment ]
            [ text "Click Fast!" ]
-}
leading : Wrapper msg -> Time -> msg -> msg
leading wrap delay msg =
    wrap <| leading_ wrap delay msg


leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrap delay msg =
    SM.modifyAndGet (State.increment msg)
        |> SM.andThen (leadingDeferred >> Ctl.later wrap delay)
        |> SM.when State.isEmpty (Ctl.batch <| HP.mkCmd msg)


leadingDeferred : State msg -> Control msg
leadingDeferred oldState =
    SM.condition (State.isSame oldState)
        (Ctl.reset)
        (Ctl.noCmd)



-- TRAILING EDGE #####################################################


{-| Debounce on trailing edge ("later").

    debounce : Msg -> Msg
    debounce = Control.Debounce.trailing Deb (1 * Time.second)

    view model = input [map debounce <| onInput Text] []
-}
trailing : Wrapper msg -> Time -> msg -> msg
trailing wrap delay msg =
    wrap <| trailing_ wrap delay msg


trailing_ : Wrapper msg -> Time -> msg -> Control msg
trailing_ wrap delay msg =
    SM.modifyAndGet (State.increment msg)
        |> SM.andThen (trailingDeferred >> Ctl.later wrap delay)


trailingDeferred : State msg -> Control msg
trailingDeferred oldState =
    SM.condition (State.isSame oldState)
        (Ctl.performAndReset)
        (Ctl.noCmd)



-- BOTH EDGES ########################################################


{-| Debounce on both leading and trailing edges.

The trailing edge happen only if at least 2 messages are captured.
We don't want to trigger two times the same event.

    debounce : Msg -> Msg
    debounce = Control.Debounce.both Deb (1 * Time.second)

    view model =
        button
            [ map debounce <| onClick Increment ]
            [ text "Click Fast!" ]
-}
both : Wrapper msg -> Time -> msg -> msg
both wrap delay msg =
    wrap <|
        SM.condition State.isEmpty
            (leading_ wrap delay msg)
            (trailing_ wrap delay msg)
