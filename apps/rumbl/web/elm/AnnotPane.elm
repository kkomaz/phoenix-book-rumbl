port module AnnotPane exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- import Html.Events exposing (..)

import Html.App as App
import Time
import Phoenix.Socket


-- import Phoenix.Channel
-- import Phoenix.Push
-- model


type alias Model =
    { annots : List Annot
    , inputMessage : String
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type alias Annot =
    { at : Int
    , name : String
    , text : String
    }


initModel : ( Model, Cmd Msg )
initModel =
    ( Model
        []
        ""
        (Phoenix.Socket.init "ws://localhost:4000/socket/websocket")
    , Cmd.none
    )



-- update


type Msg
    = Received Annot
    | Post String
    | Timeout Float
    | CurTime Int
    | InitSocket String
    | JoinChannel String
    | PhoenixMsg (Phoenix.Socket.Msg Msg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Received annot ->
            ( model, Cmd.none )

        Post text ->
            ( model, Cmd.none )

        Timeout time ->
            -- Debug.log "Timeout" ( model, rewind (round time) )
            ( model, rewind (round time) )

        CurTime time ->
            -- let
            --     log =
            --         Debug.log "time" time
            -- in
            ( model, Cmd.none )

        InitSocket path ->
            ( { model
                | phxSocket = (Phoenix.Socket.init path |> Phoenix.Socket.withDebug)
              }
            , Cmd.none
            )

        JoinChannel channel ->
            ( model, Cmd.none )

        PhoenixMsg msg ->
            let
                ( socket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = socket }
                , Cmd.map PhoenixMsg phxCmd
                )



-- subscription


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every Time.second Timeout
        , curTime CurTime
        , initSocket InitSocket
        , Phoenix.Socket.listen model.phxSocket PhoenixMsg
        ]



-- port


port initSocket : (String -> msg) -> Sub msg


port joinChannel : (String -> msg) -> Sub msg


port rewind : Int -> Cmd msg


port curTime : (Int -> msg) -> Sub msg



-- view


view : Model -> Html Msg
view model =
    div [ class "panel panel-default" ]
        [ div [ class "panel-heading" ]
            [ h3 [ class "panel-title" ]
                [ text "Annotations" ]
            ]
        , div [ class "panel-body annotations", id "msg-container" ]
            []
        , div [ class "panel-footer" ]
            [ textarea [ class "form-control", id "msg-input", placeholder "Comment...", attribute "rows" "3" ]
                []
            , button [ class "btn btn-primary form-control", id "msg-submit", type' "submit" ]
                [ text "Post" ]
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
