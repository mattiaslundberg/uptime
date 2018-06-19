module CheckForm exposing (..)

import Dict
import Json.Encode
import Json.Decode exposing (field)
import Bootstrap.Grid as Grid
import Html.Events exposing (onSubmit, onInput, onClick)
import Bootstrap.Form.Input as Input
import Bootstrap.Form as Form
import Bootstrap.Button as Button
import Html exposing (Html, li, text, div, ul, form, label, input, button, span, h1, h2, a)
import Html.Attributes exposing (value, for, type_, class, href)


type alias Errors =
    { errors : Dict.Dict String String
    }


type alias Model =
    { id : Int
    , url : String
    , notifyNumber : String
    , expectedCode : Int
    }


type Msg
    = SetUrl String
    | SetNumber String
    | SetResponse String
    | Submit


init : Model
init =
    { id = 0
    , url = ""
    , notifyNumber = ""
    , expectedCode = 200
    }


submitCmd : Model -> String
submitCmd model =
    if model.id == 0 then
        "create_check"
    else
        "update_check"


serializer : Model -> List ( String, Json.Encode.Value )
serializer model =
    if model.id == 0 then
        [ ( "url", Json.Encode.string model.url ), ( "notify_number", Json.Encode.string model.notifyNumber ), ( "expected_code", Json.Encode.int model.expectedCode ) ]
    else
        [ ( "id", Json.Encode.int model.id ), ( "url", Json.Encode.string model.url ), ( "notify_number", Json.Encode.string model.notifyNumber ), ( "expected_code", Json.Encode.int model.expectedCode ) ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetUrl str ->
            ( { model | url = str }, Cmd.none )

        SetNumber str ->
            ( { model | notifyNumber = str }, Cmd.none )

        SetResponse str ->
            let
                newValue =
                    Result.withDefault model.expectedCode (String.toInt str)
            in
                ( { model | expectedCode = newValue }, Cmd.none )

        Submit ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ drawEditMessage model
        , Form.form [ onSubmit Submit ]
            [ Form.group []
                [ Form.label [ for "url" ] [ text "Url" ]
                , Input.text [ Input.id "url", Input.attrs [ value model.url, onInput SetUrl ] ]
                ]
            , Form.group []
                [ Form.label [ for "notify_no" ] [ text "Notify number" ]
                , Input.text [ Input.id "notify_no", Input.attrs [ value model.notifyNumber, onInput SetNumber ] ]
                ]
            , Form.group []
                [ Form.label [ for "expected_code" ] [ text "Expected response code" ]
                , Input.text [ Input.id "expected_code", Input.attrs [ value (toString model.expectedCode), onInput SetResponse ] ]
                ]
            , Button.button [ Button.attrs [ type_ "submit" ] ] [ text "Save" ]
            ]
        ]


drawEditMessage : Model -> Html Msg
drawEditMessage model =
    let
        t =
            if model.id == 0 then
                "Create new check"
            else
                "Edit check"
    in
        Grid.row [] [ Grid.col [] [ h2 [ class "text-center" ] [ text t ] ] ]


decoder : Json.Decode.Decoder Errors
decoder =
    Json.Decode.map Errors
        (field "errors" (Json.Decode.dict Json.Decode.string))


handlePushError : Model -> Json.Encode.Value -> Model
handlePushError model raw =
    case Json.Decode.decodeValue decoder raw of
        Ok val ->
            model

        Err error ->
            model
