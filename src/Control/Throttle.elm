module Control.Throttle
    exposing
        ( leading
        , trailing
        , both
        )

{-| Throttle messages.

Throttling is similar to debouncing,
except that instead of triggering only 1 message of a group of messages,
it triggers one every certain amount of time.

For a complete minimalist example,
please refer to the file: examples/ThrottleButton.elm

@docs leading, trailing, both

-}

import Time exposing (Time)
import Control as Ctl exposing (State, Wrapper, Control)
import Control_ as Ctl
import StateMonad as SM
import Helpers as HP
import State


-- LEADING EDGE ######################################################


{-| Throttle on leading edge ("immediate").

    throttle : Msg -> Msg
    throttle = Control.Throttle.leading Throttle (1 * Time.second)

    view model =
        button
            [ map throttle <| onClick Increment ]
            [ text "Click Fast!" ]
-}
leading : Wrapper msg -> Time -> msg -> msg
leading wrap delay msg =
    wrap <| leading_ wrap delay msg


leading_ : Wrapper msg -> Time -> msg -> Control msg
leading_ wrap delay msg =
    SM.condition State.isEmpty
        (Ctl.later wrap delay Ctl.reset
            |> Ctl.batch (HP.mkCmd msg)
        )
        (SM.return Cmd.none)
        |> SM.mapState (State.increment msg)



-- TRAILING EDGE #####################################################


{-| Throttle on trailing edge ("later").

    throttle : Msg -> Msg
    throttle = Control.Throttle.trailing Throttle (1 * Time.second)

    view model =
        button
            [ map throttle <| onClick Increment ]
            [ text "Click Fast!" ]
-}
trailing : Wrapper msg -> Time -> msg -> msg
trailing wrap delay msg =
    wrap <| trailing_ wrap delay msg


trailing_ : Wrapper msg -> Time -> msg -> Control msg
trailing_ wrap delay msg =
    SM.condition State.isEmpty
        (Ctl.later wrap delay <| trailingDeferred True wrap delay)
        (SM.return Cmd.none)
        |> SM.mapState (State.increment msg)


trailingDeferred : Bool -> Wrapper msg -> Time -> Control msg
trailingDeferred newMessage wrap delay state =
    let
        ( _, maybeMsg ) =
            State.get state
    in
        if newMessage && State.isUnique state then
            ( State.init, State.cmd state )
        else if State.isUnique state then
            ( State.init, Cmd.none )
        else
            ( State.set 1 maybeMsg
            , Cmd.batch
                [ State.cmd state
                , trailingDeferred False wrap delay
                    |> wrap
                    |> HP.mkDeferredCmd delay
                ]
            )



-- BOTH EDGES ########################################################


{-| Throttle on both leading and trailing edges.

The trailing edge happen only if at least 2 messages are captured.
We don't want to trigger two times the same event.

    throttle : Msg -> Msg
    throttle = Control.Throttle.both Throttle (1 * Time.second)

    view model =
        button
            [ map throttle <| onClick Increment ]
            [ text "Click Fast!" ]
-}
both : Wrapper msg -> Time -> msg -> msg
both wrap delay msg =
    wrap <| both_ wrap delay msg


both_ : Wrapper msg -> Time -> msg -> Control msg
both_ wrap delay msg =
    SM.condition State.isEmpty
        (trailingDeferred False wrap delay
            |> Ctl.later wrap delay
            |> Ctl.batch (HP.mkCmd msg)
        )
        (SM.return Cmd.none)
        |> SM.mapState (State.increment msg)
