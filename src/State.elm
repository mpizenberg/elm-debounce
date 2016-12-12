module State
    exposing
        ( State
        , set
        , get
        , init
        , increment
          -- Queries
        , isEmpty
        , isUnique
        , isN
        , isSame
          -- Export cmd
        , cmd
        )

{-| Private State module.
-}

import Helpers


type State msg
    = State Int (Maybe msg)


set : Int -> Maybe msg -> State msg
set int maybeMsg =
    State int maybeMsg


get : State msg -> ( Int, Maybe msg )
get (State int maybeMsg) =
    ( int, maybeMsg )


init : State msg
init =
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


isSame : State msg -> State msg -> Bool
isSame (State n1 _) (State n2 _) =
    n1 == n2


cmd : State msg -> Cmd msg
cmd (State _ maybeMsg) =
    case maybeMsg of
        Nothing ->
            Cmd.none

        Just msg ->
            Helpers.mkCmd msg
