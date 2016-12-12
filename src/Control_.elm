module Control_ exposing (..)

import Time exposing (Time)
import Helpers
import Control exposing (..)
import StateMonad as SM
import State


reset : Control msg
reset =
    SM.set State.init Cmd.none


performAndReset : Control msg
performAndReset state =
    ( State.init, State.cmd state )


performAndInit : Control msg
performAndInit state =
    let
        ( _, maybeMsg ) =
            State.get state
    in
        ( State.set 1 maybeMsg, State.cmd state )


later : Wrapper msg -> Time -> Control msg -> Control msg
later wrap delay control =
    control |> wrap |> Helpers.mkDeferredCmd delay |> SM.return


batch : Cmd msg -> Control msg -> Control msg
batch cmd =
    SM.map (\cmd_ -> Cmd.batch [ cmd_, cmd ])
