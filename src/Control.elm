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


isN : Int -> State msg -> Bool
isN n (State int _) =
    n == int


sameState : State msg -> State msg -> Bool
sameState (State n1 _) (State n2 _) =
    n1 == n2



-- TYPES #############################################################


type alias Wrapper msg =
    Control msg -> msg


type alias Return msg =
    SM.Return (State msg) (Cmd msg)


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


init : State msg -> Control msg
init state _ =
    ( state, Cmd.none )


reset : Control msg
reset =
    init initialState


resetIfSame : State msg -> State msg -> Control msg
resetIfSame oldState newState =
    if sameState oldState newState then
        reset
    else
        init newState


later : Wrapper msg -> Time -> Control msg -> Control msg
later wrapper delay control state =
    ( state
    , wrapper control
        |> Helpers.mkDeferredCmd delay
    )


batch : Cmd msg -> Control msg -> Control msg
batch cmd2 =
    SM.map (\cmd1 -> Cmd.batch [ cmd1, cmd2 ])