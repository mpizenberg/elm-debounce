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
-}
debouncing : Time -> Strategy
debouncing timeout =
    Debounce timeout


{-| Create a throttling strategy.
-}
throttling : Time -> Strategy
throttling delay =
    Throttle delay


{-| Control state to be stored in the model.
-}
type State msg
    = State Int (Maybe msg)


{-| Initial state.
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


{-| A wrapper for the internal messages.
-}
type alias MsgWrapper msg =
    Msg msg -> msg


{-| Inverse wrapper, wrap an outside message into an internal message.
-}
wrap : msg -> Msg msg
wrap =
    Raw


{-| Update the controlled state of a message.
-}
update : MsgWrapper msg -> Strategy -> Msg msg -> State msg -> ( State msg, Cmd msg )
update msgWrapper strategy controlMsg currentState =
    case ( controlMsg, strategy ) of
        ( Raw msg, _ ) ->
            let
                newState =
                    currentState
                        |> increment msg

                cmd =
                    case strategy of
                        Debounce timeout ->
                            Deferred newState msg
                                |> msgWrapper
                                |> Helpers.mkDeferredCmd timeout

                        Throttle delay ->
                            if uniqueMsg newState then
                                performNowAndLoop msg delay msgWrapper
                            else
                                Cmd.none
            in
                ( newState, cmd )

        ( Deferred oldState oldMsg, _ ) ->
            ( currentState
            , if sameState oldState currentState then
                Helpers.mkCmd oldMsg
              else
                Cmd.none
            )

        ( Loop, Throttle delay ) ->
            case currentState of
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
