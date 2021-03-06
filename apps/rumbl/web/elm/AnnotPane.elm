port module AnnotPane exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App
import Time
import Phoenix.Socket as PSocket
import Phoenix.Channel as PChannel
import Phoenix.Push as PPush
import Json.Encode as JE
import Json.Decode as JD exposing ((:=))


-- model


type alias Model =
    { annots : List Annot
    , playtime : Int
    , text : String
    , phxSocket : PSocket.Socket Msg
    , chId : String
    }


type alias Annot =
    { id : Int
    , at : Int
    , name : String
    , text : String
    }


initModel : ( Model, Cmd Msg )
initModel =
    ( Model
        []
        0
        ""
        (PSocket.init "ws://localhost:4000/socket/websocket")
        ""
    , Cmd.none
    )



-- update


type Msg
    = Received (List Annot)
    | ReceivedOne Annot
    | Clicked Annot
    | InputText String
    | Post
    | Timer
    | Playtime Int
    | InitSocket String
    | JoinChannel String
    | PhoenixMsg (PSocket.Msg Msg)
    | Noop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Received annots ->
            ( { model | annots = annots }, Cmd.none )

        ReceivedOne annot ->
            ( { model | annots = (annot :: model.annots) }, Cmd.none )

        Clicked annot ->
            ( model, seek annot.at )

        InputText text ->
            ( { model | text = text }, Cmd.none )

        Post ->
            let
                payload =
                    (JE.object [ ( "body", JE.string model.text ), ( "at", JE.int model.playtime ) ])

                push =
                    PPush.init "new_annotation" model.chId |> PPush.withPayload payload

                ( phxSocket, phxCmd ) =
                    PSocket.push push model.phxSocket
            in
                ( { model | phxSocket = phxSocket, text = "" }, Cmd.map PhoenixMsg phxCmd )

        -- let payload = {body: msgInput.value, at: Player.getCurrentTime()}
        -- vidChannel.push("new_annotation", payload)
        Timer ->
            ( model, reportPlaytime {} )

        Playtime time ->
            ( { model | playtime = (Debug.log "Playtime" time) }, Cmd.none )

        InitSocket path ->
            ( { model
                | phxSocket = (PSocket.init path |> PSocket.withDebug)
              }
            , Cmd.none
            )

        JoinChannel channel ->
            let
                pChannel =
                    PChannel.init (Debug.log "Channel" channel)
                        |> PChannel.onJoin onReceiveJoin

                pSocket =
                    model.phxSocket
                        |> PSocket.on "new_annotation"
                            channel
                            onReceiveAnnot

                ( socket, phxCmd ) =
                    PSocket.join pChannel pSocket
            in
                ( { model | phxSocket = socket, chId = channel }
                , Cmd.map PhoenixMsg phxCmd
                )

        PhoenixMsg msg ->
            let
                ( socket, phxCmd ) =
                    PSocket.update msg model.phxSocket
            in
                ( { model | phxSocket = socket }
                , Cmd.map PhoenixMsg phxCmd
                )

        Noop ->
            ( model, Cmd.none )


onReceiveJoin : JE.Value -> Msg
onReceiveJoin raw =
    case JD.decodeValue decodeJoin (Debug.log "Raw" raw) of
        Ok annots ->
            Received annots

        Err error ->
            Received []


onReceiveAnnot : JE.Value -> Msg
onReceiveAnnot raw =
    case JD.decodeValue decodeAnnot (Debug.log "Raw" raw) of
        Ok annot ->
            ReceivedOne annot

        Err error ->
            Noop


decodeJoin : JD.Decoder (List Annot)
decodeJoin =
    JD.at [ "annotations" ] (JD.list decodeAnnot)


decodeAnnot : JD.Decoder Annot
decodeAnnot =
    JD.object4 Annot ("id" := JD.int) ("at" := JD.int) (JD.at [ "user", "username" ] JD.string) ("body" := JD.string)



-- subscription


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every Time.second (always Timer)
        , initSocket InitSocket
        , joinChannel JoinChannel
        , playtime Playtime
        , PSocket.listen model.phxSocket PhoenixMsg
        ]



-- Cmd port


port reportPlaytime : {} -> Cmd msg


port seek : Int -> Cmd msg



-- Sub port


port initSocket : (String -> msg) -> Sub msg


port joinChannel : (String -> msg) -> Sub msg


port playtime : (Int -> msg) -> Sub msg



-- view


view : Model -> Html Msg
view model =
    let
        annots =
            List.sortBy (\a -> ( a.at, a.id )) model.annots
                |> List.filter (\a -> a.at <= model.playtime)
    in
        div [ class "panel panel-default" ]
            [ div [ class "panel-heading" ]
                [ h3 [ class "panel-title" ]
                    [ text "Annotations - Elm" ]
                ]
            , div [ class "panel-body annotations", id "msg-container" ]
                (List.map
                    annotView
                    annots
                )
            , div [ class "panel-footer" ]
                [ textarea [ onInput InputText, value model.text, class "form-control", id "msg-input", placeholder "Comment...", attribute "rows" "3" ]
                    []
                , button [ onClick Post, class "btn btn-primary form-control", id "msg-submit", type' "submit" ]
                    [ text "Post" ]
                ]
              -- , div [] [ text (toString { text = model.text, annots = model.annots }) ]
            ]


make2Digit : Int -> String
make2Digit n =
    if n >= 10 then
        toString n
    else
        "0" ++ toString n


mmss : Int -> String
mmss time =
    let
        t =
            time // 1000

        min =
            t // 60

        sec =
            t % 60
    in
        (make2Digit min) ++ ":" ++ (make2Digit sec)


annotView : Annot -> Html Msg
annotView annot =
    div []
        [ a [ onClick (Clicked annot) ]
            [ text ("[" ++ (mmss annot.at) ++ "] ")
            , b [] [ text annot.name ]
            , text (": " ++ annot.text)
            ]
        ]


main : Program Never
main =
    App.program
        { init = initModel
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
