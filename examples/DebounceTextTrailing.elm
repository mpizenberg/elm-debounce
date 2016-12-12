module Main exposing (..)

import Html exposing (Html)
import Html.Events as HE
import Html.Attributes as HA
import Time
import Control exposing (Control)
import Control.Debounce as Debounce


main =
    Html.program
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }



-- MODEL #############################################################


type alias Model =
    { text : String
    , state : Control.State Msg
    }


initialModel : Model
initialModel =
    { text = "", state = Control.initialState }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



-- UPDATE ############################################################


type Msg
    = Text String
    | Deb (Control Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Text text ->
            ( { model | text = text }
            , Cmd.none
            )

        Deb control ->
            Control.update
                (\newstate -> { model | state = newstate })
                model.state
                control



-- VIEW ##############################################################


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.p []
            [ Html.input
                [ HA.placeholder "Enter text here"
                , HA.map debounce <| HE.onInput Text
                ]
                []
            ]
        , Html.p []
            [ Html.text model.text ]
        ]


debounce : Msg -> Msg
debounce =
    Debounce.trailing Deb (1 * Time.second)
