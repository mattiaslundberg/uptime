port module Ports exposing (..)

import Models exposing (ConnData)


port jsGetToken : (ConnData -> msg) -> Sub msg


port getToken : String -> Cmd msg
