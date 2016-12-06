module Controller exposing (..)

import Time exposing (Time)
import Helpers
import State as S


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
    Controller msg -> msg



-- UPDATE ############################################################


type alias Controller msg =
    S.State (State msg) (Cmd msg)


update : State msg -> Controller msg -> ( Cmd msg, State msg )
update =
    S.runState



-- DEBOUNCING ########################################################


deferred_ : State msg -> State msg -> ( Cmd msg, State msg )
deferred_ oldState newState =
    if sameState oldState newState then
        ( stateCmd newState, initialState )
    else
        ( Cmd.none, newState )


deferred : State msg -> Controller msg
deferred state =
    S.state <| deferred_ state


debounce_ : Wrapper msg -> Time -> msg -> State msg -> ( Cmd msg, State msg )
debounce_ wrapper timeout msg state =
    let
        newState =
            increment msg state
    in
        ( deferred newState
            |> wrapper
            |> Helpers.mkDeferredCmd timeout
        , newState
        )


debounce : Wrapper msg -> Time -> msg -> Controller msg
debounce wrapper timeout msg =
    S.state <| debounce_ wrapper timeout msg



-- THROTTLING ########################################################


throttle_ : Wrapper msg -> Time -> msg -> State msg -> ( Cmd msg, State msg )
throttle_ wrapper delay msg state =
    if empty state then
        increment msg state
            |> nowAndLoop_ wrapper delay
    else
        ( Cmd.none, increment msg state )


throttle : Wrapper msg -> Time -> msg -> Controller msg
throttle wrapper delay msg =
    S.state <| throttle_ wrapper delay msg


nowAndLoop_ : Wrapper msg -> Time -> State msg -> ( Cmd msg, State msg )
nowAndLoop_ wrapper delay state =
    ( Cmd.batch
        [ stateCmd state
        , loop wrapper delay
            |> wrapper
            |> Helpers.mkDeferredCmd delay
        ]
    , state
    )


nowAndLoop : Wrapper msg -> Time -> Controller msg
nowAndLoop wrapper delay =
    S.state <| nowAndLoop_ wrapper delay


loop_ : Wrapper msg -> Time -> State msg -> ( Cmd msg, State msg )
loop_ wrapper delay state =
    case state of
        -- Stop the loop if no new message was emitted.
        State 1 _ ->
            ( Cmd.none, initialState )

        State _ (Just msg) ->
            State 1 (Just msg)
                |> nowAndLoop_ wrapper delay

        _ ->
            ( Cmd.none, state )


loop : Wrapper msg -> Time -> Controller msg
loop wrapper delay =
    S.state <| loop_ wrapper delay
