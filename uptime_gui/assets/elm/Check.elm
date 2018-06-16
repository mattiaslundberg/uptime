module Check exposing (..)


type alias Model =
    { id : Int
    , url : String
    , notifyNumber : String
    , expectedCode : Int
    }


init : Model
init =
    Model 0 "" "" 200
