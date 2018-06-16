module App exposing (..)

import Ports exposing (..)
import Http
import Json.Encode
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
import List
import List.Extra exposing (find)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Models exposing (ConnData)


type alias Id =
    { id : Int }


type alias Check =
    { id : Int
    , url : String
    , notifyNumber : String
    , expectedCode : Int
    }


type alias Flags =
    { url : String }


type alias Model =
    { connection : Maybe Connection
    , authRequired : Bool
    , checks : List Check
    , nextCheck : Check
    , url : String
    , userName : String
    , password : String
    }


type alias Connection =
    { socket : Phoenix.Socket.Socket Msg
    , token : String
    , userId : Int
    }


type Msg
    = PhoenixMsg (Phoenix.Socket.Msg Msg)
    | SubmitForm
    | PhxAddCheck Json.Encode.Value
    | PhxDeleteCheck Json.Encode.Value
    | PhxUpdateCheck Json.Encode.Value
    | SetNewUrl String
    | SetNewNumber String
    | SetNewResponse String
    | SetNewUserName String
    | SetNewPassword String
    | SubmitAuthForm
    | DeleteCheck Int
    | EditCheck Int
    | GotToken ConnData
    | PromptAuth Bool
    | Logout
    | AuthResult (Result Http.Error ConnData)


newNextCheck : Check
newNextCheck =
    Check 0 "" "" 200


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            { connection = Nothing
            , authRequired = False
            , checks = []
            , nextCheck = newNextCheck
            , url = flags.url
            , userName = ""
            , password = ""
            }
    in
        ( model, getToken "" )


initConnection : String -> ConnData -> ( Connection, Cmd Msg )
initConnection url connData =
    let
        userId =
            connData.userId

        token =
            connData.token

        channel =
            Phoenix.Channel.init (channelName userId)
                |> Phoenix.Channel.withPayload (Json.Encode.object [ ( "token", Json.Encode.string token ) ])

        ( initSocket, cmd ) =
            Phoenix.Socket.init url
                |> Phoenix.Socket.withDebug
                |> Phoenix.Socket.on "create_check" (channelName userId) PhxAddCheck
                |> Phoenix.Socket.on "remove_check" (channelName userId) PhxDeleteCheck
                |> Phoenix.Socket.on "update_check" (channelName userId) PhxUpdateCheck
                |> Phoenix.Socket.join channel
    in
        ( { socket = initSocket, token = token, userId = userId }, Cmd.map PhoenixMsg cmd )


channelName : Int -> String
channelName userId =
    "checks:" ++ toString userId


idDecoder : Json.Decode.Decoder Id
idDecoder =
    Json.Decode.map Id
        (field "id" Json.Decode.int)


checkDecoder : Json.Decode.Decoder Check
checkDecoder =
    Json.Decode.map4 Check
        (field "id" Json.Decode.int)
        (field "url" Json.Decode.string)
        (field "notify_number" Json.Decode.string)
        (field "expected_code" Json.Decode.int)


connDecoder : Json.Decode.Decoder ConnData
connDecoder =
    Json.Decode.map2 ConnData
        (field "token" Json.Decode.string)
        (field "user_id" Json.Decode.int)


updateSocket : Phoenix.Socket.Msg Msg -> Model -> ( Model, Cmd Msg )
updateSocket msg model =
    case model.connection of
        Just conn ->
            let
                ( socket, cmd ) =
                    Phoenix.Socket.update msg conn.socket
            in
                ( { model | connection = Just { conn | socket = socket } }, Cmd.map PhoenixMsg cmd )

        Nothing ->
            ( model, Cmd.none )


push : String -> Json.Encode.Value -> Connection -> ( Connection, Cmd Msg )
push command payload conn =
    let
        cmd =
            Phoenix.Push.init command (channelName conn.userId) |> Phoenix.Push.withPayload payload

        ( socket, phxCmd ) =
            Phoenix.Socket.push cmd conn.socket
    in
        ( { conn | socket = socket }, Cmd.map PhoenixMsg phxCmd )


getSubmitCommand : Check -> String
getSubmitCommand check =
    if check.id == 0 then
        "create_check"
    else
        "update_check"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg msg ->
            updateSocket msg model

        PhxAddCheck raw ->
            case Json.Decode.decodeValue checkDecoder raw of
                Ok check ->
                    ( { model | checks = check :: model.checks }
                    , Cmd.none
                    )

                Err error ->
                    Debug.log (error)
                        ( model, Cmd.none )

        PhxDeleteCheck raw ->
            case Json.Decode.decodeValue idDecoder raw of
                Ok data ->
                    ( { model | checks = List.filter (\c -> c.id /= data.id) model.checks }, Cmd.none )

                Err error ->
                    Debug.log (error) ( model, Cmd.none )

        PhxUpdateCheck raw ->
            case Json.Decode.decodeValue checkDecoder raw of
                Ok check ->
                    ( { model | checks = updateCheck model.checks check }, Cmd.none )

                Err error ->
                    Debug.log (error) ( model, Cmd.none )

        GotToken connData ->
            let
                ( conn, cmd ) =
                    initConnection model.url connData
            in
                ( { model | connection = Just conn }, cmd )

        PromptAuth required ->
            ( { model | authRequired = required }, Cmd.none )

        SetNewUrl str ->
            let
                current =
                    model.nextCheck
            in
                ( { model | nextCheck = { current | url = str } }, Cmd.none )

        SetNewNumber str ->
            let
                current =
                    model.nextCheck
            in
                ( { model | nextCheck = { current | notifyNumber = str } }, Cmd.none )

        SetNewResponse str ->
            let
                current =
                    model.nextCheck

                newValue =
                    Result.withDefault model.nextCheck.expectedCode (String.toInt str)
            in
                ( { model | nextCheck = { current | expectedCode = newValue } }, Cmd.none )

        SubmitForm ->
            case model.connection of
                Just conn ->
                    let
                        payload =
                            Json.Encode.object (generateFormSerializer model.nextCheck)

                        ( newConn, phxCmds ) =
                            push (getSubmitCommand model.nextCheck) payload conn
                    in
                        ( { model | connection = Just newConn, nextCheck = newNextCheck }, phxCmds )

                Nothing ->
                    ( model, Cmd.none )

        SetNewUserName str ->
            ( { model | userName = str }, Cmd.none )

        SetNewPassword str ->
            ( { model | password = str }, Cmd.none )

        SubmitAuthForm ->
            let
                url =
                    "http://localhost:4000/api/login"

                payload =
                    (Json.Encode.object [ ( "email", Json.Encode.string model.userName ), ( "password", Json.Encode.string model.password ) ])

                request =
                    Http.post url (Http.jsonBody payload) connDecoder
            in
                ( model, Http.send AuthResult request )

        AuthResult (Ok connData) ->
            let
                ( conn, connCmd ) =
                    initConnection model.url connData

                tokenCmd =
                    setToken ( connData.token, toString connData.userId )
            in
                ( { model | connection = Just conn, authRequired = False }, Cmd.batch [ connCmd, tokenCmd ] )

        AuthResult (Err err) ->
            Debug.log "error"
                ( model, Cmd.none )

        Logout ->
            let
                tokenCmd =
                    unsetToken ""
            in
                ( { model | connection = Nothing, authRequired = True }, tokenCmd )

        DeleteCheck checkId ->
            case model.connection of
                Just conn ->
                    let
                        payload =
                            (Json.Encode.object [ ( "id", Json.Encode.int checkId ) ])

                        ( nextConn, phxCmds ) =
                            push "remove_check" payload conn
                    in
                        ( { model | connection = Just nextConn }, phxCmds )

                Nothing ->
                    ( model, Cmd.none )

        EditCheck checkId ->
            let
                check =
                    Maybe.withDefault model.nextCheck (find (\c -> c.id == checkId) model.checks)
            in
                ( { model | nextCheck = check }, Cmd.none )


updateCheck : List Check -> Check -> List Check
updateCheck checks check =
    List.map (updateIfMatch check) checks


updateIfMatch : Check -> Check -> Check
updateIfMatch candidate current =
    if current.id == candidate.id then
        candidate
    else
        current


generateFormSerializer : Check -> List ( String, Json.Encode.Value )
generateFormSerializer check =
    if check.id == 0 then
        [ ( "url", Json.Encode.string check.url ), ( "notify_number", Json.Encode.string check.notifyNumber ), ( "expected_code", Json.Encode.int check.expectedCode ) ]
    else
        [ ( "id", Json.Encode.int check.id ), ( "url", Json.Encode.string check.url ), ( "notify_number", Json.Encode.string check.notifyNumber ), ( "expected_code", Json.Encode.int check.expectedCode ) ]


drawCheck : Check -> Table.Row Msg
drawCheck check =
    Table.tr []
        [ Table.td [] [ text check.url ]
        , Table.td [] [ text check.notifyNumber ]
        , Table.td [] [ text (toString check.expectedCode) ]
        , Table.td []
            [ ButtonGroup.buttonGroup []
                [ ButtonGroup.button [ Button.attrs [ onClick (EditCheck check.id) ] ]
                    [ text "🖋️" ]
                , ButtonGroup.button
                    [ Button.attrs [ onClick (DeleteCheck check.id) ] ]
                    [ text "❌" ]
                ]
            ]
        ]


drawChecks : List Check -> Html Msg
drawChecks model =
    Table.simpleTable
        ( Table.simpleThead
            [ Table.th [] [ text "Url" ]
            , Table.th [] [ text "Notify number" ]
            , Table.th [] [ text "Expected response" ]
            , Table.th [] [ text "Actions" ]
            ]
        , Table.tbody []
            (model
                |> List.map drawCheck
            )
        )


drawEditMessage : Check -> Html Msg
drawEditMessage check =
    let
        t =
            if check.id == 0 then
                "Create new check"
            else
                "Edit check"
    in
        Grid.row [] [ Grid.col [] [ h2 [ class "text-center" ] [ text t ] ] ]


drawForm : Check -> List (Html Msg)
drawForm check =
    [ drawEditMessage check
    , Form.form [ onSubmit SubmitForm ]
        [ Form.group []
            [ Form.label [ for "url" ] [ text "Url" ]
            , Input.text [ Input.id "url", Input.attrs [ value check.url, onInput SetNewUrl ] ]
            ]
        , Form.group []
            [ Form.label [ for "notify_no" ] [ text "Notify number" ]
            , Input.text [ Input.id "notify_no", Input.attrs [ value check.notifyNumber, onInput SetNewNumber ] ]
            ]
        , Form.group []
            [ Form.label [ for "expected_code" ] [ text "Expected response code" ]
            , Input.text [ Input.id "expected_code", Input.attrs [ value (toString check.expectedCode), onInput SetNewResponse ] ]
            ]
        , Button.button [ Button.attrs [ type_ "submit", class "float-right" ] ] [ text "Save" ]
        ]
    ]


drawAuthenticated : Model -> Html Msg
drawAuthenticated model =
    div []
        ([ a [ href "#", onClick Logout, class "float-right" ] [ text "Logout" ]
         , div []
            [ CDN.stylesheet
            , Grid.container []
                ([ Grid.row [] [ Grid.col [] [ h1 [ class "text-center" ] [ text "Uptime" ] ] ]
                 , Grid.row [] [ Grid.col [] [ div [ class "text-center" ] [ text "Monitors uptime for selected sites and notifies by text in case of problems." ] ] ]
                 , Grid.row [] [ Grid.col [] [ h2 [ class "text-center" ] [ text "Active checks" ] ] ]
                 , Grid.row [] [ Grid.col [] [ text " " ] ]
                 ]
                    ++ [ drawChecks model.checks ]
                )
            ]
         ]
            ++ drawForm model.nextCheck
        )


drawAuthForm : Model -> Html Msg
drawAuthForm model =
    div []
        [ div []
            [ CDN.stylesheet
            , Form.form
                [ onSubmit SubmitAuthForm ]
                [ Form.group []
                    [ Form.label [ for "user" ] [ text "Username" ]
                    , Input.text [ Input.id "user", Input.attrs [ onInput SetNewUserName ] ]
                    ]
                , Form.group []
                    [ Form.label [ for "password" ] [ text "Password" ]
                    , Input.text [ Input.id "password", Input.attrs [ type_ "password", onInput SetNewPassword ] ]
                    ]
                , Button.button [ Button.attrs [ type_ "submit", class "float-right" ] ] [ text "Login" ]
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    if model.authRequired then
        drawAuthForm model
    else
        drawAuthenticated model


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.connection of
        Just conn ->
            Sub.batch
                [ Phoenix.Socket.listen conn.socket PhoenixMsg
                , jsGetToken GotToken
                , jsPromptAuth PromptAuth
                ]

        Nothing ->
            Sub.batch
                [ jsGetToken GotToken
                , jsPromptAuth PromptAuth
                ]


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
