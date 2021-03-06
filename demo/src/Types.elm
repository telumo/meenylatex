module Types exposing (..)

import MiniLatex.Parser exposing (LatexExpression)
import MiniLatex.Differ exposing (EditRecord)
import Html exposing (Html)
import Time exposing (Posix)


type alias Model a =
    { counter : Int
    , sourceText : String
    , sourceText2 : String
    , parseResult : List (List LatexExpression)
    , inputString : String
    , hasMathResult : List Bool
    , editRecord : EditRecord a
    , seed : Int
    , configuration : Configuration
    , lineViewStyle : LineViewStyle
    , windowHeight : Int
    , windowWidth : Int
    , startTime : Posix
    , stopTime : Posix
    , message : String
    }


type Msg
    = FastRender
    | GetContent String
    | ReRender
    | Reset
    | Restore
    | GenerateSeed
    | NewSeed Int
    | ShowStandardView
    | ShowParseResultsView
    | ShowRawHtmlView
    | ShowRenderToLatexView
    | SetHorizontalView
    | SetVerticalView
    | TechReport
    | WavePackets
    | WeatherApp
    | MathPaper
    | Grammar
    | Input String
    | RequestStartTime
    | RequestStopTime
    | ReceiveStartTime Posix
    | ReceiveStopTime Posix


type LineViewStyle
    = Horizontal
    | Vertical


type Configuration
    = StandardView
    | ParseResultsView
    | RawHtmlView
    | RenderToLatexView
