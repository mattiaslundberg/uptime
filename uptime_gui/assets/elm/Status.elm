module Status exposing (..)

import Html exposing (Html, div, text)
import Json.Decode exposing (field)
import Bootstrap.Alert as Alert


type alias Model =
    { message : String, status : String, visibility : Alert.Visibility }


type alias StatusMsg =
    { statusMsg : String }


type Msg
    = Set String String
    | Reset
    | AlertMsg Alert.Visibility


init : Model
init =
    { message = "", status = "", visibility = Alert.closed }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Set message status ->
            ( { model | message = message, status = status, visibility = Alert.shown }, Cmd.none )

        Reset ->
            ( { model | message = "", visibility = Alert.closed }, Cmd.none )

        AlertMsg visibility ->
            ( { model | visibility = visibility }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        role =
            if model.status == "error" then
                Alert.warning
            else
                Alert.success
    in
        Alert.config
            |> role
            |> Alert.dismissable AlertMsg
            |> Alert.children [ text model.message ]
            |> Alert.view model.visibility


decoder : Json.Decode.Decoder StatusMsg
decoder =
    Json.Decode.map StatusMsg
        (field "status_msg" Json.Decode.string)
