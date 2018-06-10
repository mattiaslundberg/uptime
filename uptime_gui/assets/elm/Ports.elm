port module Ports exposing (..)


port jsGetToken : (String -> msg) -> Sub msg


port getToken : String -> Cmd msg
