module Throttle exposing (..)

{-| Throttle messages.
-}

import Time exposing (Time)
import Control as Ctl exposing (State, Wrapper, Control)
import StateMonad as SM
import Helpers as HP


-- LEADING EDGE ######################################################


{-| Throttle on leading edge ("immediate").
-}
leading : Wrapper msg -> Time -> msg -> msg
leading wrap delay msg =
    wrap <| leading_ wrap delay msg


leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrap delay msg =
    SM.condition Ctl.isEmpty
        (Ctl.later wrap delay Ctl.reset
            |> Ctl.batch (HP.mkCmd msg)
        )
        (SM.return Cmd.none)
        |> SM.mapState (Ctl.increment msg)



-- TRAILING EDGE #####################################################
