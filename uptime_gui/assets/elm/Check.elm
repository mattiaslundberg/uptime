module Check exposing (..)

import Json.Decode exposing (field)


type alias Model =
    { id : Int
    , url : String
    , notifyNumber : String
    , expectedCode : Int
    }


init : Model
init =
    Model 0 "" "" 200


decoder : Json.Decode.Decoder Model
decoder =
    Json.Decode.map4 Model
        (field "id" Json.Decode.int)
        (field "url" Json.Decode.string)
        (field "notify_number" Json.Decode.string)
        (field "expected_code" Json.Decode.int)
