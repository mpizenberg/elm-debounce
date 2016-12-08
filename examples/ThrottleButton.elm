module Main exposing (..)

import Html exposing (Html)
import Html.Events as HE
import Html.Attributes as HA
import Time
import Control exposing (Control)
import Throttle


main =
    Html.program
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }



-- MODEL #############################################################


type alias Model =
    { count : Int
    , state : Control.State Msg
    }


init : ( Model, Cmd Msg )
init =
    ( { count = 0, state = Control.initialState }
    , Cmd.none
    )



-- UPDATE ############################################################


type Msg
    = Increment
    | Throttle (Control Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }
            , Cmd.none
            )

        Throttle control ->
            Control.update model.state control
                |> Control.updateState (\newState -> { model | state = newState })



-- VIEW ##############################################################


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.button
            [ HA.map throttle <| HE.onClick Increment ]
            [ Html.text "Click Fast!" ]
        , Html.text <| toString model.count
        ]


throttle : Msg -> Msg
throttle =
    Throttle.both Throttle (2 * Time.second)
