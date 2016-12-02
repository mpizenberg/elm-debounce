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
    { count : Int
    , state : MsgControl.State Msg
    }


init : ( Model, Cmd Msg )
init =
    ( { count = 0, state = MsgControl.init }
    , Cmd.none
    )



-- UPDATE ############################################################


type Msg
    = Increment
    | Debounce (MsgControl.Msg Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }
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
        [ Html.button
            [ HA.map debounce <| HE.onClick Increment ]
            [ Html.text "Increment" ]
        , Html.text <| toString model.count
        ]


debounce : Msg -> Msg
debounce =
    Debounce << MsgControl.wrap
