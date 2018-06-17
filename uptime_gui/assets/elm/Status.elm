module Status exposing (..)

import Html exposing (Html, div, text)


type alias Model =
    { message : String, status : String }


type Msg
    = Set String String


init : Model
init =
    { message = "", status = "" }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Set message status ->
            ( { model | message = message, status = status }, Cmd.none )


view : Model -> Html Msg
view model =
    div [] [ text model.message ]
