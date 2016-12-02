module Main exposing (..)

import Html exposing (Html)
import Html.Events as HE
import Html.Attributes as HA
import Time
import MsgControl


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
    , state : MsgControl.State Msg
    }


initialModel : Model
initialModel =
    { text = "", state = MsgControl.init }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



-- UPDATE ############################################################


type Msg
    = Text String
    | Debounce (MsgControl.Msg Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Text text ->
            ( { model | text = text }
            , Cmd.none
            )

        Debounce controlMsg ->
            let
                ( newState, cmd ) =
                    MsgControl.update
                        (Debounce)
                        (MsgControl.debouncing <| 1 * Time.second)
                        (controlMsg)
                        (model.state)
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
    Debounce << MsgControl.wrap
