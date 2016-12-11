module Control exposing (..)

import Time exposing (Time)
import Helpers
import StateMonad as SM


-- STATE #############################################################


type State msg
    = State Int (Maybe msg)


initialState : State msg
initialState =
    State 0 Nothing


increment : msg -> State msg -> State msg
increment msg (State n _) =
    State (n + 1) (Just msg)


isEmpty : State msg -> Bool
isEmpty =
    isN 0


isUnique : State msg -> Bool
isUnique =
    isN 1


isN : Int -> State msg -> Bool
isN n (State int _) =
    n == int


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



-- TYPES #############################################################


type alias Wrapper msg =
    Control msg -> msg


type alias Return msg =
    ( State msg, Cmd msg )


type alias Control msg =
    SM.State (State msg) (Cmd msg)



-- UPDATE ############################################################


updateState : (State msg -> model) -> Return msg -> ( model, Cmd msg )
updateState setState ( state, cmd ) =
    ( setState state, cmd )


update : State msg -> Control msg -> Return msg
update =
    SM.run



-- HELPERS ###########################################################


batch : Cmd msg -> Control msg -> Control msg
batch cmd =
    SM.map (\cmd_ -> Cmd.batch [ cmd_, cmd ])
