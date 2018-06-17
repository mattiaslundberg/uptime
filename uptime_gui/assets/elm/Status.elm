module Status exposing (..)

import Html exposing (Html, div, text)
import Json.Decode exposing (field)
import Bootstrap.Alert as Alert


type alias Model =
    { message : String, status : String }


type alias StatusMsg =
    { statusMsg : String }


type Msg
    = Set String String
    | Reset


init : Model
init =
    { message = "", status = "" }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Set message status ->
            ( { model | message = message, status = status }, Cmd.none )

        Reset ->
            ( { model | message = "" }, Cmd.none )


view : Model -> Html Msg
view model =
    if model.status == "error" && model.message /= "" then
        Alert.simpleWarning [] [ text model.message ]
    else if model.status == "success" && model.message /= "" then
        Alert.simpleSuccess [] [ text model.message ]
    else
        div [] []


decoder : Json.Decode.Decoder StatusMsg
decoder =
    Json.Decode.map StatusMsg
        (field "status_msg" Json.Decode.string)
