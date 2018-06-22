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


viewList : List Model -> Html ()
viewList models =
    div []
        (List.map (\m -> view m) models)


view : Model -> Html ()
view model =
    div [] [ text model.name ]
