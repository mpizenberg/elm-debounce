module Throttle exposing (..)

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
        |> if Ctl.empty state then
            Return.effect_
                (Helpers.mkDeferredCmd timeout
                    << wrapper
                    << trailingDeferred wrapper timeout
                )
           else
            identity


trailingDeferred : Wrapper msg -> Time -> State msg -> Control msg
trailingDeferred wrapper timeout oldState newState =
    case ( oldState, newState ) of
        ( Ctl.State 1 (Just msg), Ctl.State 1 _ ) ->
            Ctl.initialState
                |> Return.singleton
                |> Return.command (Helpers.mkCmd msg)

        ( Ctl.State 1 _, Ctl.State _ (Just msg) ) ->
            Ctl.initialState
                |> Return.singleton
                |> Return.command (Helpers.mkCmd msg)
                |> Return.effect_
                    (Helpers.mkDeferredCmd timeout
                        << wrapper
                        << trailingDeferred wrapper timeout
                    )

        _ ->
            Return.singleton newState



-- LEADING EDGE ######################################################


leading : Wrapper msg -> Time -> msg -> msg
leading wrapper delay msg =
    wrapper <| leading_ wrapper delay msg


leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrapper delay msg state =
    (Ctl.increment msg state)
        |> Return.singleton
        |> (if Ctl.empty state then
                Return.command (Helpers.mkCmd msg)
                    >> Return.effect_
                        (Helpers.mkDeferredCmd delay
                            << wrapper
                            << leadingDeferred
                        )
            else
                identity
           )


leadingDeferred : State msg -> Control msg
leadingDeferred _ _ =
    Return.singleton Ctl.initialState



-- BOTH EDGES ########################################################


both : Wrapper msg -> Time -> msg -> msg
both wrapper delay msg =
    wrapper <| both_ wrapper delay msg


both_ : Wrapper msg -> Time -> msg -> Control msg
both_ wrapper delay msg state =
    (Ctl.increment msg state)
        |> Return.singleton
        |> (if Ctl.empty state then
                Return.command (Helpers.mkCmd msg)
                    >> Return.effect_
                        (Helpers.mkDeferredCmd delay
                            << wrapper
                            << bothDeferred wrapper delay
                        )
            else
                identity
           )


bothDeferred : Wrapper msg -> Time -> State msg -> Control msg
bothDeferred wrapper timeout oldState newState =
    case ( oldState, newState ) of
        ( Ctl.State 1 (Just msg), Ctl.State 1 _ ) ->
            Ctl.initialState
                |> Return.singleton

        ( Ctl.State 1 _, Ctl.State _ (Just msg) ) ->
            Ctl.State 1 (Just msg)
                |> Return.singleton
                |> Return.command (Helpers.mkCmd msg)
                |> Return.effect_
                    (Helpers.mkDeferredCmd timeout
                        << wrapper
                        << bothDeferred wrapper timeout
                    )

        _ ->
            Return.singleton newState
