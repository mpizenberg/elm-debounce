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
-}
type alias State msg =
    State.State msg


{-| Initialisation of the internal state.
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
-}
type alias Wrapper msg =
    Control msg -> msg



-- UPDATE ############################################################


{-| Update your model.

It needs a user defined State setter to be able to
update the state inside the model.
-}
update : (State msg -> model) -> State msg -> Control msg -> ( model, Cmd msg )
update setState state control =
    SM.run state control
        |> Tuple.mapFirst setState
