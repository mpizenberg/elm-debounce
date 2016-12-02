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
    | Throttle (MsgControl.Msg Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }
            , Cmd.none
            )

        Throttle controlMsg ->
            let
                ( newState, cmd ) =
                    MsgControl.update
                        (Throttle)
                        (MsgControl.throttling <| 1 * Time.second)
                        (controlMsg)
                        (model.state)
            in
                ( { model | state = newState }, cmd )



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
    Throttle << MsgControl.wrap
