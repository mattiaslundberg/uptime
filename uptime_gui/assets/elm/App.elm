module App exposing (..)

import Ports exposing (..)
import Contact
import Bootstrap.Navbar as Navbar
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


type Page
    = Checks
    | Contacts
    | About
    | Login


type alias Model =
    { connection : Maybe Connection
    , checks : List Check.Model
    , checkForm : CheckForm.Model
    , url : String
    , login : Login.Model
    , status : Status.Model
    , navbar : Navbar.State
    , page : Page
    }


type alias Connection =
    { socket : Phoenix.Socket.Socket Msg
    , token : String
    , userId : Int
    }


type Msg
    = Noop ()
    | PhxMsg (Phoenix.Socket.Msg Msg)
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
    | NavbarMsg Navbar.State
    | PageMsg Page


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg

        model =
            { connection = Nothing
            , checks = []
            , checkForm = CheckForm.init
            , url = flags.url
            , login = Login.init
            , status = Status.init
            , navbar = navbarState
            , page = Checks
            }
    in
        ( model, Cmd.batch [ getToken "", navbarCmd ] )


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
        Noop _ ->
            ( model, Cmd.none )

        PageMsg p ->
            ( { model | page = p }, Cmd.none )

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
            ( { model | page = Login }, Cmd.none )

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
                            ( { model | connection = Just conn, page = Checks }, Cmd.batch [ connCmd, tokenCmd ] )

                    Nothing ->
                        ( { model | login = loginModel }, Cmd.map LoginMsg loginCmd )

        Logout ->
            let
                tokenCmd =
                    unsetToken ""
            in
                ( { model | connection = Nothing, page = Login }, tokenCmd )

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

        NavbarMsg state ->
            ( { model | navbar = state }, Cmd.none )

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
        , Table.td [] [ Html.map Noop (Contact.viewList check.contacts) ]
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
        ([ Grid.row [] [ Grid.col [] [ h2 [ class "text-center" ] [ text "Active checks" ] ] ]
         , Grid.row [] [ Grid.col [] [ text " " ] ]
         ]
            ++ [ drawChecks model.checks ]
            ++ [ Html.map CheckFormMsg (CheckForm.view model.checkForm) ]
        )


navbarItem : Page -> Page -> Msg -> String -> Navbar.Item Msg
navbarItem currentPage page event label =
    let
        fun =
            if currentPage == page then
                Navbar.itemLinkActive
            else
                Navbar.itemLink
    in
        fun [ href "#", onClick event ] [ text label ]


viewNavbar : Model -> Html Msg
viewNavbar model =
    Navbar.config NavbarMsg
        |> Navbar.withAnimation
        |> Navbar.brand [ href "#" ] [ text "Uptime" ]
        |> Navbar.items
            [ navbarItem model.page Checks (PageMsg Checks) "Active checks"
            , navbarItem model.page Contacts (PageMsg Contacts) "Contacts"
            , navbarItem model.page About (PageMsg About) "About"
            , Navbar.itemLink [ href "#", onClick Logout, class "d-flex justify-content-end" ] [ text "Logout" ]
            ]
        |> Navbar.view model.navbar


statusView : Model -> Html Msg
statusView model =
    Html.map StatusMsg (Status.view model.status)


view : Model -> Html Msg
view model =
    case model.page of
        Login ->
            div []
                [ CDN.stylesheet
                , statusView model
                , Grid.container [] [ Html.map LoginMsg (Login.view model.login) ]
                ]

        Checks ->
            div []
                [ CDN.stylesheet
                , Grid.container
                    []
                    [ viewNavbar model
                    , statusView model
                    , drawAuthenticated model
                    ]
                ]

        Contacts ->
            div []
                [ CDN.stylesheet
                , Grid.container
                    []
                    [ viewNavbar model, statusView model, text "Contact list" ]
                ]

        About ->
            div [] [ CDN.stylesheet, Grid.container [] [ viewNavbar model, statusView model, text "About" ] ]


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.connection of
        Just conn ->
            Sub.batch
                [ Phoenix.Socket.listen conn.socket PhxMsg
                , jsGetToken GotToken
                , jsPromptAuth PromptAuth
                , Navbar.subscriptions model.navbar NavbarMsg
                ]

        Nothing ->
            Sub.batch
                [ jsGetToken GotToken
                , jsPromptAuth PromptAuth
                , Navbar.subscriptions model.navbar NavbarMsg
                ]


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
