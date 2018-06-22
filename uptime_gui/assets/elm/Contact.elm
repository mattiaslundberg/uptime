module Contact exposing (..)

import Json.Decode exposing (field)
import Html exposing (Html, div, text)


type alias Model =
    { id : Int
    , name : String
    , number : String
    }


decoder : Json.Decode.Decoder Model
decoder =
    Json.Decode.map3 Model
        (field "id" Json.Decode.int)
        (field "name" Json.Decode.string)
        (field "number" Json.Decode.string)


viewNames : List Model -> Html ()
viewNames models =
    div []
        (List.map (\m -> viewName m) models)


viewName : Model -> Html ()
viewName model =
    div [] [ text model.name ]
