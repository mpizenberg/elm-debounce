module Main exposing (..)

import Html exposing (Html)
import Html.Events as HE
import Html.Attributes as HA
import Time
import String
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
    { rawText : String
    , debText : String
    , state : Controller.State Msg
    }


initialModel : Model
initialModel =
    { rawText = "", debText = "", state = Controller.initialState }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )



-- UPDATE ############################################################


type Msg
    = RawText String
    | DebText String
    | Deb (Controller Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RawText rawText ->
            { model | rawText = String.toLower rawText }
                |> update (debounce <| DebText rawText)

        -- |> mapModel (\model -> { model | rawText = rawText })
        DebText debText ->
            ( { model | debText = String.toUpper debText }
            , Cmd.none
            )

        Deb controller ->
            Controller.update model.state controller
                |> Controller.updateState (\newState -> { model | state = newState })


debounce : Msg -> Msg
debounce =
    Deb << Controller.debounce Deb (1 * Time.second)


mapModel : (Model -> Model) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
mapModel f ( model, cmd ) =
    ( f model, cmd )



-- VIEW ##############################################################


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.p []
            [ Html.input
                [ HA.placeholder "Enter text here"
                , HE.onInput RawText
                ]
                []
            ]
        , Html.p []
            [ Html.text ("Not debounced text (and toLower): " ++ model.rawText) ]
        , Html.p []
            [ Html.text ("Debounced text (and toUpper): " ++ model.debText) ]
        ]
