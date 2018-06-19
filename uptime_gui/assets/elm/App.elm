module App exposing (..)

import Ports exposing (..)
import Check
import Login
import CheckForm
import Json.Encode
import Status
import Bootstrap.Table as Table
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
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
    , checkForm : CheckForm.Model
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
    = PhxMsg (Phoenix.Socket.Msg Msg)
    | PhxPushError Json.Encode.Value
    | PhxAddCheck Json.Encode.Value
    | PhxDeleteCheck Json.Encode.Value
    | PhxUpdateCheck Json.Encode.Value
    | CheckFormMsg CheckForm.Msg
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
            , checkForm = CheckForm.init
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


handlePhxMsg : Phoenix.Socket.Msg Msg -> Model -> ( Model, Cmd Msg )
handlePhxMsg msg model =
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
            Phoenix.Push.init command (channelName conn.userId)
                |> Phoenix.Push.withPayload payload
                |> Phoenix.Push.onError PhxPushError
                |> Phoenix.Push.onOk handlePushOk

        ( socket, phxCmd ) =
            Phoenix.Socket.push cmd conn.socket
    in
        ( { conn | socket = socket }, Cmd.map PhxMsg phxCmd )


handlePushOk : Json.Encode.Value -> Msg
handlePushOk raw =
    case Json.Decode.decodeValue Status.decoder raw of
        Ok val ->
            StatusMsg (Status.Set val.statusMsg "success")

        Err error ->
            StatusMsg Status.Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhxMsg msg ->
            handlePhxMsg msg model

        PhxPushError raw ->
            let
                statusModel =
                    Status.handlePushError model.status raw

                formModel =
                    CheckForm.handlePushError model.checkForm raw
            in
                ( { model | status = statusModel, checkForm = formModel }, Cmd.none )

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

        CheckFormMsg msg ->
            case msg of
                -- TODO: Move submit to Form module if possible
                CheckForm.Submit ->
                    case model.connection of
                        Just conn ->
                            let
                                payload =
                                    Json.Encode.object (CheckForm.serializer model.checkForm)

                                ( newConn, phxCmds ) =
                                    push (CheckForm.submitCmd model.checkForm) payload conn
                            in
                                ( { model | connection = Just newConn, checkForm = CheckForm.init }, phxCmds )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    let
                        ( cfModel, cfCmd ) =
                            CheckForm.update msg model.checkForm
                    in
                        ( { model | checkForm = cfModel }, Cmd.map CheckFormMsg cfCmd )

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
                    CheckForm.fromCheck (Maybe.withDefault (CheckForm.toCheck model.checkForm) (find (\c -> c.id == checkId) model.checks))
            in
                ( { model | checkForm = check }, Cmd.none )


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
            ++ [ Html.map CheckFormMsg (CheckForm.view model.checkForm) ]
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
