module Debounce exposing (..)

{-| Debounce messages.
-}

import Time exposing (Time)
import Control exposing (State, Wrapper, Control)
import StateMonad as SM
import Helpers


init : State msg
init =
    Control.initialState



-- LEADING EDGE ######################################################


{-| Debounce on leading edge ("immediate").
-}
leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrapper delay msg state =
    let
        newState =
            Control.increment msg state
    in
        SM.get
            |> SM.andThen (Control.resetIfSame newState)
            |> Control.later wrapper delay
            |> SM.filter
                (Control.isN 1)
                (Control.batch <| Helpers.mkCmd msg)
            |> SM.run newState


{-| Debounce on leading edge ("immediate").
-}
leading : Wrapper msg -> Time -> msg -> msg
leading wrapper delay msg =
    leading_ wrapper delay msg
        |> wrapper



-- TRAILING EDGE #####################################################


{-| Debounce on trailing edge ("later").
-}
trailing_ : Wrapper msg -> Time -> msg -> Control msg
trailing_ wrapper delay msg state =
    let
        newState =
            Control.increment msg state
    in
        SM.get
            |> SM.condition (Control.sameState newState)
                (always Control.reset
                    >> Control.batch (Helpers.mkCmd msg)
                )
                (SM.andThen Control.init)
            |> Control.later wrapper delay
            |> SM.run newState


{-| Debounce on trailing edge ("later").
-}
trailing : Wrapper msg -> Time -> msg -> msg
trailing wrapper delay msg =
    trailing_ wrapper delay msg
        |> wrapper



-- BOTH EDGES ########################################################


{-| Debounce on both leading and trailing edges.

The trailing edge happen only if at least 2 messages are captured.
We don't want to emit two times the same event.
-}
both : Wrapper msg -> Time -> msg -> msg
both wrapper delay msg =
    SM.get
        |> SM.condition (Control.isEmpty)
            (always <| leading_ wrapper delay msg)
            (always <| trailing_ wrapper delay msg)
        |> wrapper
