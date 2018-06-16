module Login exposing (..)

import Http
import Json.Encode
import Json.Decode exposing (field)
import Models exposing (ConnData)
import Bootstrap.Table as Table
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.Form.Input as Input
import Bootstrap.Form as Form
import Bootstrap.Button as Button
import Bootstrap.ButtonGroup as ButtonGroup
import Json.Decode exposing (field)
import Html exposing (Html, li, text, div, ul, form, label, input, button, span, h1, h2, a)
import Html.Attributes exposing (value, for, type_, class, href)
import Html.Events exposing (onSubmit, onInput, onClick)


type alias Model =
    { userName : String
    , password : String
    }


type Msg
    = SetPwd String
    | SetUser String
    | Submit
    | AuthResult (Result Http.Error ConnData)


init : Model
init =
    { userName = "", password = "" }


update : Msg -> Model -> ( Model, Cmd Msg, Maybe ConnData )
update msg model =
    case msg of
        SetUser str ->
            ( { model | userName = str }, Cmd.none, Nothing )

        SetPwd str ->
            ( { model | password = str }, Cmd.none, Nothing )

        Submit ->
            let
                url =
                    "http://localhost:4000/api/login"

                payload =
                    (Json.Encode.object [ ( "email", Json.Encode.string model.userName ), ( "password", Json.Encode.string model.password ) ])

                request =
                    Http.post url (Http.jsonBody payload) connDecoder
            in
                ( model, Http.send AuthResult request, Nothing )

        AuthResult (Ok connData) ->
            ( model, Cmd.none, Just connData )

        AuthResult (Err err) ->
            Debug.log "error"
                ( model, Cmd.none, Nothing )


connDecoder : Json.Decode.Decoder ConnData
connDecoder =
    Json.Decode.map2 ConnData
        (field "token" Json.Decode.string)
        (field "user_id" Json.Decode.int)


view : Model -> Html Msg
view model =
    Form.form
        [ onSubmit Submit ]
        [ Form.group []
            [ Form.label [ for "user" ] [ text "Username" ]
            , Input.text [ Input.id "user", Input.attrs [ onInput SetUser ] ]
            ]
        , Form.group []
            [ Form.label [ for "password" ] [ text "Password" ]
            , Input.text [ Input.id "password", Input.attrs [ type_ "password", onInput SetPwd ] ]
            ]
        , Button.button [ Button.attrs [ type_ "submit", class "float-right" ] ] [ text "Login" ]
        ]
