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


{-| Throttle on trailing edge ("later").
-}
trailing : Wrapper msg -> Time -> msg -> msg
trailing wrap delay msg =
    wrap <| trailing_ wrap delay msg


trailing_ : Wrapper msg -> Time -> msg -> Control msg
trailing_ wrap delay msg =
    SM.condition Ctl.isEmpty
        (Ctl.later wrap delay <| trailingDeferred True wrap delay)
        (SM.return Cmd.none)
        |> SM.mapState (Ctl.increment msg)


trailingDeferred : Bool -> Wrapper msg -> Time -> Control msg
trailingDeferred newMessage wrap delay ((Ctl.State n maybeMsg) as state) =
    if newMessage && Ctl.isUnique state then
        ( Ctl.initialState, Ctl.stateCmd state )
    else if Ctl.isUnique state then
        ( Ctl.initialState, Cmd.none )
    else
        ( Ctl.State 1 maybeMsg
        , Cmd.batch
            [ Ctl.stateCmd state
            , HP.mkDeferredCmd delay <| wrap <| trailingDeferred False wrap delay
            ]
        )
