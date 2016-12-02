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


{-| The controlling strategy.
-}
type Strategy
    = Debounce Time
    | Throttle Time


{-| Create a debouncing strategy.

    strategy = MsgControl.debouncing <| 1 * Time.second
-}
debouncing : Time -> Strategy
debouncing timeout =
    Debounce timeout


{-| Create a throttling strategy.

    strategy = MsgControl.throttling <| 50 * Time.millisecond
-}
throttling : Time -> Strategy
throttling delay =
    Throttle delay


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
    | Loop


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
update : MsgWrapper msg -> Strategy -> Msg msg -> State msg -> ( State msg, Cmd msg )
update msgWrapper strategy controlMsg currentState =
    case ( controlMsg, strategy ) of
        -- A Raw msg encapsulates an event to control.
        ( Raw msg, _ ) ->
            let
                newState =
                    currentState
                        |> increment msg

                cmd =
                    case strategy of
                        -- If we chose a Debounce strategy, debounce the msg.
                        Debounce timeout ->
                            Deferred newState msg
                                |> msgWrapper
                                |> Helpers.mkDeferredCmd timeout

                        -- If we chose a Throttle strategy, throttle the msg.
                        Throttle delay ->
                            if uniqueMsg newState then
                                -- Only perform the captured message
                                -- if it is the first one.
                                performNowAndLoop msg delay msgWrapper
                            else
                                -- Ignore otherwise.
                                Cmd.none
            in
                ( newState, cmd )

        -- A Deferred msg encapsulates an old msg that we will perform
        -- only if no new message was emitted since this was deferred.
        ( Deferred oldState oldMsg, _ ) ->
            ( currentState
            , if sameState oldState currentState then
                Helpers.mkCmd oldMsg
              else
                Cmd.none
            )

        -- Loop will simply perform the more recent message
        -- and reprogram itself for later.
        ( Loop, Throttle delay ) ->
            case currentState of
                -- Stop the loop if no new message was emitted.
                State 1 _ ->
                    ( init, Cmd.none )

                State _ (Just msg) ->
                    ( State 1 (Just msg)
                    , performNowAndLoop msg delay msgWrapper
                    )

                _ ->
                    ( currentState, Cmd.none )

        _ ->
            ( currentState, Cmd.none )


performNowAndLoop : msg -> Time -> MsgWrapper msg -> Cmd msg
performNowAndLoop msg delay msgWrapper =
    Cmd.batch
        [ Helpers.mkCmd msg
        , Helpers.mkDeferredCmd delay (msgWrapper Loop)
        ]
