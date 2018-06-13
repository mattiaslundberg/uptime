port module Ports exposing (..)

import Models exposing (ConnData)


port jsGetToken : (ConnData -> msg) -> Sub msg


port jsPromptAuth : (Bool -> msg) -> Sub msg


port getToken : String -> Cmd msg


port setToken : ( String, String ) -> Cmd msg
