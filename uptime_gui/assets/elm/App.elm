module App exposing (..)

import Ports exposing (..)
import Check
import Login
import Json.Encode
import Status
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


type alias Flags =
    { url : String }


type alias Model =
    { connection : Maybe Connection
    , authRequired : Bool
    , checks : List Check.Model
    , nextCheck : Check.Model
    , url : String
    , login : Login.Model
    , status : Status.Model
    }


type alias Connection =
    { socket : Phoenix.Socket.Socket Msg
    , token : String
    , userId : Int
    }


type Msg
    = SubmitForm
    | PhxMsg (Phoenix.Socket.Msg Msg)
    | PhxAddCheck Json.Encode.Value
    | PhxDeleteCheck Json.Encode.Value
    | PhxUpdateCheck Json.Encode.Value
    | SetNewUrl String
    | SetNewNumber String
    | SetNewResponse String
    | LoginMsg Login.Msg
    | StatusMsg Status.Msg
    | DeleteCheck Int
    | EditCheck Int
    | GotToken ConnData
    | PromptAuth Bool
    | Logout


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            { connection = Nothing
            , authRequired = False
            , checks = []
            , nextCheck = Check.init
            , url = flags.url
            , login = Login.init
            , status = Status.init
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
        ( { socket = initSocket, token = token, userId = userId }, Cmd.map PhxMsg cmd )


channelName : Int -> String
channelName userId =
    "checks:" ++ toString userId


idDecoder : Json.Decode.Decoder Id
idDecoder =
    Json.Decode.map Id
        (field "id" Json.Decode.int)


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
                ( { model | connection = Just { conn | socket = socket } }, Cmd.map PhxMsg cmd )

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
        ( { conn | socket = socket }, Cmd.map PhxMsg phxCmd )


getSubmitCommand : Check.Model -> String
getSubmitCommand check =
    if check.id == 0 then
        "create_check"
    else
        "update_check"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhxMsg msg ->
            updateSocket msg model

        PhxAddCheck raw ->
            case Json.Decode.decodeValue Check.decoder raw of
                Ok check ->
                    ( { model | checks = check :: model.checks }
                    , Cmd.none
                    )

                Err error ->
                    handlePhxError error model

        PhxDeleteCheck raw ->
            case Json.Decode.decodeValue idDecoder raw of
                Ok data ->
                    ( { model | checks = List.filter (\c -> c.id /= data.id) model.checks }, Cmd.none )

                Err error ->
                    handlePhxError error model

        PhxUpdateCheck raw ->
            case Json.Decode.decodeValue Check.decoder raw of
                Ok check ->
                    ( { model | checks = updateCheck model.checks check }, Cmd.none )

                Err error ->
                    handlePhxError error model

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
                        ( { model | connection = Just newConn, nextCheck = Check.init }, phxCmds )

                Nothing ->
                    ( model, Cmd.none )

        StatusMsg msg ->
            let
                ( statusModel, statusCmd ) =
                    Status.update msg model.status
            in
                ( { model | status = statusModel }, Cmd.map StatusMsg statusCmd )

        LoginMsg msg ->
            let
                ( loginModel, loginCmd, connData ) =
                    Login.update msg model.login
            in
                case connData of
                    Just connData ->
                        let
                            ( conn, connCmd ) =
                                initConnection model.url connData

                            tokenCmd =
                                setToken ( connData.token, toString connData.userId )
                        in
                            ( { model | connection = Just conn, authRequired = False }, Cmd.batch [ connCmd, tokenCmd ] )

                    Nothing ->
                        ( { model | login = loginModel }, Cmd.map LoginMsg loginCmd )

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


handlePhxError : String -> Model -> ( Model, Cmd Msg )
handlePhxError error model =
    let
        ( newStatus, statusCmd ) =
            Status.update (Status.Set error "error") model.status
    in
        ( { model | status = newStatus }, Cmd.map StatusMsg statusCmd )


updateCheck : List Check.Model -> Check.Model -> List Check.Model
updateCheck checks check =
    List.map (updateIfMatch check) checks


updateIfMatch : Check.Model -> Check.Model -> Check.Model
updateIfMatch candidate current =
    if current.id == candidate.id then
        candidate
    else
        current


generateFormSerializer : Check.Model -> List ( String, Json.Encode.Value )
generateFormSerializer check =
    if check.id == 0 then
        [ ( "url", Json.Encode.string check.url ), ( "notify_number", Json.Encode.string check.notifyNumber ), ( "expected_code", Json.Encode.int check.expectedCode ) ]
    else
        [ ( "id", Json.Encode.int check.id ), ( "url", Json.Encode.string check.url ), ( "notify_number", Json.Encode.string check.notifyNumber ), ( "expected_code", Json.Encode.int check.expectedCode ) ]


drawCheck : Check.Model -> Table.Row Msg
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


drawChecks : List Check.Model -> Html Msg
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


drawEditMessage : Check.Model -> Html Msg
drawEditMessage check =
    let
        t =
            if check.id == 0 then
                "Create new check"
            else
                "Edit check"
    in
        Grid.row [] [ Grid.col [] [ h2 [ class "text-center" ] [ text t ] ] ]


drawForm : Check.Model -> List (Html Msg)
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
        , Button.button [ Button.attrs [ type_ "submit" ] ] [ text "Save" ]
        ]
    ]


drawAuthenticated : Model -> Html Msg
drawAuthenticated model =
    div []
        ([ a [ href "#", onClick Logout, class "d-flex justify-content-end" ] [ text "Logout" ]
         , Grid.row [] [ Grid.col [] [ h1 [ class "text-center" ] [ text "Uptime" ] ] ]
         , Grid.row [] [ Grid.col [] [ div [ class "text-center" ] [ text "Monitors uptime for selected sites and notifies by text in case of problems." ] ] ]
         , Grid.row [] [ Grid.col [] [ h2 [ class "text-center" ] [ text "Active checks" ] ] ]
         , Grid.row [] [ Grid.col [] [ text " " ] ]
         ]
            ++ [ drawChecks model.checks ]
            ++ drawForm model.nextCheck
        )


view : Model -> Html Msg
view model =
    let
        main =
            if model.authRequired then
                Html.map LoginMsg (Login.view model.login)
            else
                drawAuthenticated model
    in
        div []
            [ CDN.stylesheet
            , Grid.container [] [ Html.map StatusMsg (Status.view model.status), main ]
            ]


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.connection of
        Just conn ->
            Sub.batch
                [ Phoenix.Socket.listen conn.socket PhxMsg
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
