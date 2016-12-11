module Debounce exposing (..)

{-| Debounce messages.
-}

import Time exposing (Time)
import Control as Ctl exposing (State, Wrapper, Control)
import StateMonad as SM
import Helpers as HP


-- LEADING EDGE ######################################################


{-| Debounce on leading edge ("immediate").
-}
leading : Wrapper msg -> Time -> msg -> msg
leading wrap delay msg =
    wrap <| leading_ wrap delay msg


{-| Debounce on leading edge ("immediate").
-}
leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrap delay msg =
    SM.modifyAndGet (Ctl.increment msg)
        |> SM.andThen
            (leadingDeferred >> wrap >> HP.mkDeferredCmd delay >> SM.return)
        |> SM.when Ctl.isEmpty (Ctl.batch <| HP.mkCmd msg)


leadingDeferred : State msg -> Control msg
leadingDeferred oldState =
    SM.condition (Ctl.sameState oldState)
        (SM.set Ctl.initialState Cmd.none)
        (SM.return Cmd.none)



-- TRAILING EDGE #####################################################


{-| Debounce on trailing edge ("later").
-}
trailing : Wrapper msg -> Time -> msg -> msg
trailing wrap delay msg =
    wrap <| trailing_ wrap delay msg


{-| Debounce on trailing edge ("later").
-}
trailing_ : Wrapper msg -> Time -> msg -> Control msg
trailing_ wrap delay msg =
    SM.modifyAndGet (Ctl.increment msg)
        |> SM.andThen
            (trailingDeferred >> wrap >> HP.mkDeferredCmd delay >> SM.return)


trailingDeferred : State msg -> Control msg
trailingDeferred oldState =
    SM.condition (Ctl.sameState oldState)
        (SM.set Ctl.initialState <| Ctl.stateCmd oldState)
        (SM.return Cmd.none)



-- BOTH EDGES ########################################################


{-| Debounce on both leading and trailing edges.

The trailing edge happen only if at least 2 messages are captured.
We don't want to emit two times the same event.
-}
both : Wrapper msg -> Time -> msg -> msg
both wrap delay msg =
    wrap <|
        SM.condition Ctl.isEmpty
            (leading_ wrap delay msg)
            (trailing_ wrap delay msg)
