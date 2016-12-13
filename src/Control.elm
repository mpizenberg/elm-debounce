-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/


module Control
    exposing
        ( State
        , initialState
        , Control
        , Wrapper
        , update
        )

{-| Common types and functions shared by Debounce and Throttle.

# Initialize the state of the message controller

@docs State, initialState

# Types aliases used in all the library

@docs Control, Wrapper

# Update your model

@docs update

-}

import StateMonad as SM
import State


-- STATE #############################################################


{-| Internal state used for controlling the messages.

    type alias Model = { ... , state : Control.State Msg }
-}
type alias State msg =
    State.State msg


{-| Initialisation of the internal state.

    initialModel = { ... , state = Control.initialState }
-}
initialState : State msg
initialState =
    State.init



-- TYPES #############################################################


{-| An alias for the specific "State Monad"
used internally for controlling the messages.
-}
type alias Control msg =
    -- SM.State (State msg) (Cmd msg)
    State msg -> ( State msg, Cmd msg )


{-| Type alias for a user defined message wrapper,
transforming `Control msg` into user `msg`.

This is usually the type constructor (`Deb` here)
you used in your Msg definition.

    type Msg = ... | Deb (Control Msg)
-}
type alias Wrapper msg =
    Control msg -> msg



-- UPDATE ############################################################


{-| Update your model.

It needs a user defined State setter to be able to
update the state inside the model.

    update msg model =
        case msg of
            ... -> ...
            Deb debMsg ->
                Control.update (\s -> { model | state = s }) model.state debMsg
-}
update : (State msg -> model) -> State msg -> Control msg -> ( model, Cmd msg )
update setState state control =
    SM.run state control
        |> Tuple.mapFirst setState
