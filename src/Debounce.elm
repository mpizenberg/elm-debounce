module Debounce exposing (..)

import Time exposing (Time)
import Helpers
import Return exposing (Return)
import Control as Ctl exposing (Wrapper, State, Control)


-- TRAILING EDGE #####################################################


trailing : Wrapper msg -> Time -> msg -> msg
trailing wrapper delay msg =
    wrapper <| trailing_ wrapper delay msg


trailing_ : Wrapper msg -> Time -> msg -> Control msg
trailing_ wrapper timeout msg state =
    (Ctl.increment msg state)
        |> Return.singleton
        |> Return.effect_
            (Helpers.mkDeferredCmd timeout << wrapper << trailingDeferred)


trailingDeferred : State msg -> Control msg
trailingDeferred oldState newState =
    if Ctl.sameState oldState newState then
        Return.return Ctl.initialState (Ctl.stateCmd newState)
    else
        Return.singleton newState



-- LEADING EDGE ######################################################


leading : Wrapper msg -> Time -> msg -> msg
leading wrapper delay msg =
    wrapper <| leading_ wrapper delay msg


leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrapper timeout msg state =
    (Ctl.increment msg state)
        |> Return.singleton
        |> Return.effect_
            (Helpers.mkDeferredCmd timeout << wrapper << leadingDeferred)
        |> Return.command
            (if Ctl.empty state then
                Helpers.mkCmd msg
             else
                Cmd.none
            )


leadingDeferred : State msg -> Control msg
leadingDeferred oldState newState =
    if Ctl.sameState oldState newState then
        Return.singleton Ctl.initialState
    else
        Return.singleton newState



-- BOTH EDGES ########################################################


both : Wrapper msg -> Time -> msg -> msg
both wrapper delay msg =
    wrapper <| both_ wrapper delay msg


both_ : Wrapper msg -> Time -> msg -> Control msg
both_ wrapper delay msg state =
    if Ctl.empty state then
        leading_ wrapper delay msg state
    else
        trailing_ wrapper delay msg state
