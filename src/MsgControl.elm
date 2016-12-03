-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/


module MsgControl
    exposing
        ( Strategy
        , debouncing
        , throttling
        , State
        , init
        , Msg
        , MsgWrapper
        , wrap
        , update
        )

{-| Control messages.

@docs Strategy, debouncing, throttling
@docs State, init
@docs Msg, MsgWrapper, wrap, update
-}

import Time exposing (Time)
import Helpers


{-| Control state to be stored in the model.

    type alias Model = { ... , state : MsgControl.State Msg }
-}
type State msg
    = State Int (Maybe msg)


{-| Initial state.

    initialModel = { ... , state = MsgControl.init }
-}
init : State msg
init =
    State 0 Nothing


{-| Increment the state.
-}
increment : msg -> State msg -> State msg
increment msg (State int _) =
    State (int + 1) (Just msg)


{-| Compare two states.
-}
sameState : State msg -> State msg -> Bool
sameState (State int1 _) (State int2 _) =
    int1 == int2


{-| Indicate if a state contains only one message or not.
-}
uniqueMsg : State msg -> Bool
uniqueMsg (State nbMsg _) =
    nbMsg == 1


{-| Internal messages.
-}
type Msg msg
    = Raw msg
    | Deferred (State msg) msg
    | Loop Time msg


{-| A wrapper for the internal controlled messages.
-}
type alias MsgWrapper msg =
    Msg msg -> msg


{-| Inverse wrapper, wrap an outside raw message into an internal message.
Key helper to control raw messages.

    view model = ... button [ HA.map debounce <| onClick Clicked ] ...

    debounce : Msg -> Msg
    debounce =
        Debounce << MsgControl.wrap
-}
wrap : msg -> Msg msg
wrap =
    Raw


{-| Update the controlled state of a message.
-}
update : MsgWrapper msg -> Strategy msg -> Msg msg -> State msg -> ( State msg, Cmd msg )
update msgWrapper strategy controlMsg currentState =
    case controlMsg of
        -- A Raw msg encapsulates an event to control.
        Raw msg ->
            increment msg currentState
                |> strategy msgWrapper msg

        -- A Deferred msg encapsulates an old msg that we will perform
        -- only if no new message was emitted since this was deferred.
        Deferred oldState oldMsg ->
            deferred oldState msgWrapper oldMsg currentState

        -- Loop will simply perform the more recent message
        -- and reprogram itself for later.
        Loop delay msg ->
            loop delay msgWrapper msg currentState


{-| The controlling strategy.
-}
type alias Strategy msg =
    MsgWrapper msg -> msg -> State msg -> ( State msg, Cmd msg )


{-| Create a debouncing strategy.

    strategy = MsgControl.debouncing <| 1 * Time.second
-}
debouncing : Time -> Strategy msg
debouncing timeout msgWrapper msg state =
    -- If we chose a Debounce strategy, debounce the msg.
    ( state
    , Deferred state msg
        |> msgWrapper
        |> Helpers.mkDeferredCmd timeout
    )


{-| Create a throttling strategy.

    strategy = MsgControl.throttling <| 50 * Time.millisecond
-}
throttling : Time -> Strategy msg
throttling delay msgWrapper msg state =
    -- If we chose a Throttle strategy, throttle the msg.
    if uniqueMsg state then
        -- Only perform the captured message
        -- if it is the first one.
        performNowAndLoop delay msgWrapper msg state
    else
        -- Ignore otherwise.
        ( state, Cmd.none )


{-| Perform a deferred message if no new message was emitted since this was deferred.
-}
deferred : State msg -> Strategy msg
deferred oldState _ oldMsg currentState =
    ( currentState
    , if sameState oldState currentState then
        Helpers.mkCmd oldMsg
      else
        Cmd.none
    )


{-| Perform the more recent message and program a the starting of a loop.
-}
performNowAndLoop : Time -> Strategy msg
performNowAndLoop delay msgWrapper msg state =
    ( state
    , Cmd.batch
        [ Helpers.mkCmd msg
        , Loop delay msg
            |> msgWrapper
            |> Helpers.mkDeferredCmd delay
        ]
    )


{-| Perform the more recent message and reprogram itself for later.
-}
loop : Time -> Strategy msg
loop delay msgWrapper _ state =
    case state of
        -- Stop the loop if no new message was emitted.
        State 1 _ ->
            ( init, Cmd.none )

        State _ (Just msg) ->
            State 1 (Just msg)
                |> performNowAndLoop delay msgWrapper msg

        _ ->
            ( state, Cmd.none )
