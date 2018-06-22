module Contact exposing (..)

import Json.Decode exposing (field)


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
