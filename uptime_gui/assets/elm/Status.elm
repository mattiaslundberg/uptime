module Status exposing (..)

import Html exposing (Html, div, text)
import Json.Decode exposing (field)
import Json.Encode
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
            ( setStatus model message status, Cmd.none )

        Reset ->
            ( { model | message = "", visibility = Alert.closed }, Cmd.none )

        AlertMsg visibility ->
            ( { model | visibility = visibility }, Cmd.none )


setStatus : Model -> String -> String -> Model
setStatus model message status =
    { model | message = message, status = status, visibility = Alert.shown }


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


handlePushError : Model -> Json.Encode.Value -> Model
handlePushError model raw =
    case Json.Decode.decodeValue decoder raw of
        Ok val ->
            setStatus model val.statusMsg "error"

        Err error ->
            setStatus model "Unknown error" "error"
