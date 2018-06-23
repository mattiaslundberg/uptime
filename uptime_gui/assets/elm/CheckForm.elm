module CheckForm exposing (..)

import Contact
import Dict
import Check
import Json.Encode
import Json.Decode exposing (field)
import Bootstrap.Grid as Grid
import Bootstrap.Form.Select as Select
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
    , contacts : List Contact.Model
    , allContacts : List Contact.Model
    , expectedCode : Int
    , errors : Dict.Dict String String
    }


type Msg
    = SetUrl String
    | AddContact String
    | SetResponse String
    | Submit


init : Model
init =
    { id = 0
    , url = ""
    , contacts = []
    , allContacts = []
    , expectedCode = 200
    , errors = Dict.empty
    }


submitCmd : Model -> String
submitCmd model =
    if model.id == 0 then
        "create_check"
    else
        "update_check"


serializer : Model -> List ( String, Json.Encode.Value )
serializer model =
    let
        extraFields =
            if model.id == 0 then
                []
            else
                [ ( "id", Json.Encode.int model.id ) ]
    in
        extraFields
            ++ [ ( "url", Json.Encode.string model.url )
               , ( "contacts", Json.Encode.list (List.map (\c -> Json.Encode.int c.id) model.contacts) )
               , ( "expected_code", Json.Encode.int model.expectedCode )
               ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetUrl str ->
            ( { model | url = str }, Cmd.none )

        AddContact str ->
            case String.toInt str of
                Ok new ->
                    ( { model | contacts = (List.filter (\c -> c.id == new) model.allContacts) ++ model.contacts }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

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
            [ Form.group [] (viewUrl model)
            , Form.group [] (viewContacts model)
            , Form.group [] (viewCode model)
            , Button.button [ Button.attrs [ type_ "submit" ] ] [ text "Save" ]
            ]
        ]


viewUrl : Model -> List (Html Msg)
viewUrl model =
    let
        extraAttrs =
            if Dict.member "url" model.errors then
                [ Input.danger ]
            else
                []
    in
        [ Form.label [ for "url" ] [ text "Url" ]
        , Input.text (extraAttrs ++ [ Input.id "url", Input.attrs [ value model.url, onInput SetUrl ] ])
        , Form.invalidFeedback [] [ text (Maybe.withDefault "" (Dict.get "url" model.errors)) ]
        ]


viewContacts : Model -> List (Html Msg)
viewContacts model =
    let
        ( feedback, extraAttrs ) =
            if Dict.member "contacts" model.errors then
                ( Maybe.withDefault "" (Dict.get "contacts" model.errors), [ Select.danger ] )
            else
                ( "", [] )
    in
        [ Form.label [ for "contacts" ] [ text "Contacts" ]
        , ul []
            (List.map (\c -> li [] [ text c.name ]) model.contacts)
        , Select.select (extraAttrs ++ [ Select.id "contacts", Select.onChange AddContact ])
            (Select.item
                []
                [ text "Add contact" ]
                :: (viewSelectContact model)
            )
        , Form.invalidFeedback [] [ text feedback ]
        ]


viewSelectContact : Model -> List (Select.Item Msg)
viewSelectContact model =
    model.allContacts
        |> List.filter (\c -> not (List.any (\a -> a.id == c.id) model.contacts))
        |> List.map
            (\c -> Select.item [ value (toString c.id) ] [ text c.name ])


viewCode : Model -> List (Html Msg)
viewCode model =
    let
        extraAttrs =
            if Dict.member "expected_code" model.errors then
                [ Input.danger ]
            else
                []
    in
        [ Form.label [ for "expected_code" ] [ text "Expected response code" ]
        , Input.text (extraAttrs ++ [ Input.id "expected_code", Input.attrs [ value (toString model.expectedCode), onInput SetResponse ] ])
        , Form.invalidFeedback [] [ text (Maybe.withDefault "" (Dict.get "notify_number" model.errors)) ]
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
            { model | errors = val.errors }

        Err error ->
            model


fromCheck : Check.Model -> Model
fromCheck check =
    { id = check.id
    , url = check.url
    , contacts = []
    , allContacts = []
    , expectedCode = check.expectedCode
    , errors = Dict.empty
    }


toCheck : Model -> Check.Model
toCheck model =
    { id = model.id
    , url = model.url
    , contacts = []
    , expectedCode = model.expectedCode
    }
