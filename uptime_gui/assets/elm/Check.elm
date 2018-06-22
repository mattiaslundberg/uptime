module Check exposing (..)

import Json.Decode exposing (field)
import Contact


type alias Model =
    { id : Int
    , url : String
    , contacts : List Contact.Model
    , expectedCode : Int
    }


init : Model
init =
    Model 0 "" [] 200


decoder : Json.Decode.Decoder Model
decoder =
    Json.Decode.map4 Model
        (field "id" Json.Decode.int)
        (field "url" Json.Decode.string)
        (field "contacts" (Json.Decode.list Contact.decoder))
        (field "expected_code" Json.Decode.int)
