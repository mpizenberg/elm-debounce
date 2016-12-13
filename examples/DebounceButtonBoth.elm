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
    | Deb (Control Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }
            , Cmd.none
            )

        Deb control ->
            Control.update
                (\newState -> { model | state = newState })
                model.state
                control



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
    Debounce.both Deb (1 * Time.second)
