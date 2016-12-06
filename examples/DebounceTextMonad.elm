module Main exposing (..)

import Html exposing (Html)
import Html.Events as HE
import Html.Attributes as HA
import Time
import Controller exposing (Controller)


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
    , state : Controller.State Msg
    }


initialModel : Model
initialModel =
    { text = "", state = Controller.initialState }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



-- UPDATE ############################################################


type Msg
    = Text String
    | Deb (Controller Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Text text ->
            ( { model | text = text }
            , Cmd.none
            )

        Deb controller ->
            let
                ( cmd, newState ) =
                    Controller.update model.state controller
            in
                ( { model | state = newState }, cmd )



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
    Deb << Controller.debounce Deb (1 * Time.second)
