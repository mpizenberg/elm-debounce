module Control exposing (..)

import Time exposing (Time)
import Helpers
import Return exposing (Return)


-- STATE #############################################################


type State msg
    = State Int (Maybe msg)


initialState : State msg
initialState =
    State 0 Nothing


empty : State msg -> Bool
empty (State n _) =
    n == 0


increment : msg -> State msg -> State msg
increment msg (State n _) =
    State (n + 1) (Just msg)


sameState : State msg -> State msg -> Bool
sameState (State n1 _) (State n2 _) =
    n1 == n2


stateCmd : State msg -> Cmd msg
stateCmd (State _ maybeMsg) =
    case maybeMsg of
        Nothing ->
            Cmd.none

        Just msg ->
            Helpers.mkCmd msg



-- WRAPPERS ##########################################################


type alias Wrapper msg =
    Control msg -> msg



-- UPDATE ############################################################


type alias Control msg =
    State msg -> Return msg (State msg)


update : State msg -> Control msg -> Return msg (State msg)
update state control =
    control state


updateState : (State msg -> model) -> ( State msg, Cmd msg ) -> ( model, Cmd msg )
updateState setState ( state, cmd ) =
    ( setState state, cmd )



-- DEBOUNCING ########################################################
-- THROTTLING ########################################################


throttle : Wrapper msg -> Time -> msg -> Control msg
throttle wrapper delay msg state =
    if empty state then
        increment msg state
            |> nowAndLoop wrapper delay
    else
        increment msg state
            |> Return.singleton


nowAndLoop : Wrapper msg -> Time -> Control msg
nowAndLoop wrapper delay state =
    Return.singleton state
        |> Return.command (stateCmd state)
        |> Return.command
            (loop wrapper delay
                |> wrapper
                |> Helpers.mkDeferredCmd delay
            )


loop : Wrapper msg -> Time -> Control msg
loop wrapper delay state =
    case state of
        -- Stop the loop if no new message was emitted.
        State 1 _ ->
            Return.singleton initialState

        State _ (Just msg) ->
            State 1 (Just msg)
                |> nowAndLoop wrapper delay

        _ ->
            Return.singleton state
