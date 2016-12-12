module Control.Debounce
    exposing
        ( leading
        , trailing
        , both
        )

{-| Debounce messages.

@docs leading, trailing, both

-}

import Time exposing (Time)
import Control as Ctl exposing (State, Wrapper, Control)
import Control_ as Ctl
import StateMonad as SM
import Helpers as HP
import State


-- LEADING EDGE ######################################################


{-| Debounce on leading edge ("immediate").
-}
leading : Wrapper msg -> Time -> msg -> msg
leading wrap delay msg =
    wrap <| leading_ wrap delay msg


leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrap delay msg =
    SM.modifyAndGet (State.increment msg)
        |> SM.andThen
            (leadingDeferred >> wrap >> HP.mkDeferredCmd delay >> SM.return)
        |> SM.when State.isEmpty (Ctl.batch <| HP.mkCmd msg)


leadingDeferred : State msg -> Control msg
leadingDeferred oldState =
    SM.condition (State.isSame oldState)
        (SM.set State.init Cmd.none)
        (SM.return Cmd.none)



-- TRAILING EDGE #####################################################


{-| Debounce on trailing edge ("later").
-}
trailing : Wrapper msg -> Time -> msg -> msg
trailing wrap delay msg =
    wrap <| trailing_ wrap delay msg


trailing_ : Wrapper msg -> Time -> msg -> Control msg
trailing_ wrap delay msg =
    SM.modifyAndGet (State.increment msg)
        |> SM.andThen
            (trailingDeferred >> wrap >> HP.mkDeferredCmd delay >> SM.return)


trailingDeferred : State msg -> Control msg
trailingDeferred oldState =
    SM.condition (State.isSame oldState)
        (SM.set State.init <| State.cmd oldState)
        (SM.return Cmd.none)



-- BOTH EDGES ########################################################


{-| Debounce on both leading and trailing edges.

The trailing edge happen only if at least 2 messages are captured.
We don't want to emit two times the same event.
-}
both : Wrapper msg -> Time -> msg -> msg
both wrap delay msg =
    wrap <|
        SM.condition State.isEmpty
            (leading_ wrap delay msg)
            (trailing_ wrap delay msg)
