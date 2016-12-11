module Throttle exposing (..)

{-| Throttle messages.
-}

import Time exposing (Time)
import Control as Ctl exposing (State, Wrapper, Control)
import StateMonad as SM
import Helpers


init : State msg
init =
    Ctl.initialState



-- LEADING EDGE ######################################################


{-| Trottle on leading edge ("immediate").

Only program a deferred process if first message.
In this case, reset state in deferred process
and perform the message now.
-}
leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrapper delay msg state =
    Ctl.get
        |> SM.filter (Ctl.isN 1)
            (always Ctl.reset
                >> Ctl.later wrapper delay
                >> (Ctl.batch <| Helpers.mkCmd msg)
            )
        |> SM.run (Ctl.increment msg state)


{-| Throttle on leading edge ("immediate").
-}
leading : Wrapper msg -> Time -> msg -> msg
leading wrapper delay msg =
    leading_ wrapper delay msg
        |> wrapper



-- TRAILING EDGE #####################################################
