module Login exposing (..)


type alias Model =
    { userName : String
    , password : String
    }


type Msg
    = SetPwd String
    | SetUser String
    | Submit


init : Model
init =
    { userName = "", password = "" }
