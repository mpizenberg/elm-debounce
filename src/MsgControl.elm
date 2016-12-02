-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/


module MsgControl
    exposing
        ( Strategy
        , debouncing
        , State
        , init
        , Msg
        , MsgWrapper
        , wrap
        , update
        )

{-| Control messages.

@docs Strategy, debouncingStrategy
@docs State, init
@docs Msg, MsgWrapper, wrap, update
-}

import Time exposing (Time)
import Helpers


{-| The controlling strategy.
-}
type Strategy
    = Debounce Time


{-| Create a debouncing strategy.
-}
debouncing : Time -> Strategy
debouncing timeout =
    Debounce timeout


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


{-| Internal messages.
-}
type Msg msg
    = Raw msg
    | Deferred (State msg) msg


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
        ( Raw msg, Debounce timeout ) ->
            let
                newState =
                    currentState
                        |> increment msg
            in
                ( newState
                , Deferred newState msg
                    |> msgWrapper
                    |> Helpers.mkDeferredCmd timeout
                )

        ( Deferred oldState oldMsg, _ ) ->
            ( currentState
            , if sameState oldState currentState then
                Helpers.mkCmd oldMsg
              else
                Cmd.none
            )
