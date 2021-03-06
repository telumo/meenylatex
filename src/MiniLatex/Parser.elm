module MiniLatex.Parser
    exposing
        ( LatexExpression(..)
        , macro
        , parse
        , defaultLatexList
        , latexList
        , endWord
        , envName
        , word
        , latexExpression
        )

{-| This module is for quickly preparing latex for export.


# API

@docs LatexExpression, macro, parse, defaultLatexList
@docs latexList, endWord, envName, word, latexExpression

-}

import Dict
import MiniLatex.ParserHelpers as PH exposing (..)
import Parser exposing (..)
import Set


{- ELLIE: https://ellie-app.com/pcB5b3BPfa1/0

   https://ellie-app.com/pcB5b3BPfa1/1

-}
{- End of Has Math code -}


{-| The type for the Abstract syntax tree
-}
type LatexExpression
    = LXString String
    | Comment String
    | Item Int LatexExpression
    | InlineMath String
    | DisplayMath String
    | SMacro String (List LatexExpression) (List LatexExpression) LatexExpression -- SMacro name optArgs args body
    | Macro String (List LatexExpression) (List LatexExpression) -- Macro name optArgs args
    | Environment String (List LatexExpression) LatexExpression -- Environment name optArgs body
    | LatexList (List LatexExpression)
    | NewCommand String Int LatexExpression
    | LXError (List DeadEnd)


{-| Transform a string into a list of LatexExpressions
-}
parse : String -> List LatexExpression
parse text =
    let
        expr =
            Parser.run latexList text
    in
        case expr of
            Ok (LatexList list) ->
                list

            Err error ->
                [ LXError error ]

            _ ->
                [ LXString "yada!" ]


parse2 : String -> LatexExpression
parse2 text =
    case Parser.run latexExpression text of
        Ok expr ->
            expr

        Err error ->
            LXError error


{-| Production: $ LatexList &\Rightarrow LatexExpression^+ $
-}
latexList : Parser LatexExpression
latexList =
    -- inContext "latexList" <|
    succeed identity
        |. ws
        |= itemList latexExpression
        |> map LatexList


{-| Production: $ LatexExpression &\Rightarrow Words\ |\ Comment\ |\ IMath\ |\ DMath\ |\ Macro\ |\ Env $
-}
latexExpression : Parser LatexExpression
latexExpression =
    oneOf
        [ texComment
        , displayMathDollar
        , displayMathBrackets
        , inlineMath ws
        , newcommand
        , macro ws
        , smacro
        , words
        , lazy (\_ -> environment)
        ]


{-| A default value of type LatexExpression
-}
defaultLatexList : LatexExpression
defaultLatexList =
    LatexList [ LXString "Parse Error" ]


defaultLatexExpression : List LatexExpression
defaultLatexExpression =
    [ Macro "NULL" [] [] ]



{- WORDS -}


words : Parser LatexExpression
words =
    oneOf
        [ blank
        , succeed identity
            |. ws
            |= words_
            |. ws
        ]


words_ : Parser LatexExpression
words_ =
    nonEmptyItemList (word notSpaceOrSpecialCharacters)
        |> map (String.join " ")
        |> map LXString


blank : Parser LatexExpression
blank =
    symbol "\n\n" |> map (\_ -> LXString "\n\n")


notSpaceOrSpecialCharacters : Char -> Bool
notSpaceOrSpecialCharacters c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$')


{-| Use `inWord` to parse a word.
-}
word : (Char -> Bool) -> Parser String
word inWord =
    succeed String.slice
        |. ws
        |= getOffset
        |. chompIf inWord
        |. chompWhile inWord
        |. ws
        |= getOffset
        |= getSource



{- MACRO WORDS -}


macroArgWords : Parser LatexExpression
macroArgWords =
    nonEmptyItemList macroArgWord
        |> map (String.join " ")
        |> map LXString


macroArgWord : Parser String
macroArgWord =
    word inMacroArg


inMacroArg : Char -> Bool
inMacroArg c =
    not (c == '\\' || c == '$' || c == '}' || c == ' ' || c == '\n')



{- OPTION ARG WORDS -}


optionArgWords : Parser LatexExpression
optionArgWords =
    nonEmptyItemList optionArgWord
        |> map (String.join " ")
        |> map LXString


optionArgWord : Parser String
optionArgWord =
    word inOptionArgWord


inOptionArgWord : Char -> Bool
inOptionArgWord c =
    not (c == '\\' || c == '$' || c == ']' || c == ' ' || c == '\n')



{- SPECIAL WORDS -}


tableCellWords : Parser LatexExpression
tableCellWords =
    nonEmptyItemList tableCellWord
        |> map (String.join " ")
        |> map String.trim
        |> map LXString


tableCellWord : Parser String
tableCellWord =
    word inTableCellWord


inTableCellWord : Char -> Bool
inTableCellWord c =
    not (c == ' ' || c == '\n' || c == '\\' || c == '$' || c == '&')



{- TEX COMMENTS -}


texComment : Parser LatexExpression
texComment =
    (getChompedString <|
        succeed ()
            |. chompIf (\c -> c == '%')
            |. chompWhile (\c -> c /= '\n')
            |. chompIf (\c -> c == '\n')
            |. ws
    )
        |> map Comment



{- MACROS -}
{- NOTE: macro sequences should be of the form "" followed by alphabetic characters,
   but not equal to certain reserved words, e.g., "\begin", "\end", "\item"
-}
-- type alias Macro2 =
--     String (List LatexExpression) (List LatexExpression)


newcommand : Parser LatexExpression
newcommand =
    succeed NewCommand
        |. symbol "\\newcommand{"
        |= macroName
        |. symbol "}"
        |= numberOfArgs
        |= arg
        |. ws


numberOfArgs_ : Parser Int
numberOfArgs_ =
    succeed identity
        |. symbol "["
        |= int
        |. symbol "]"


numberOfArgs : Parser Int
numberOfArgs =
    many numberOfArgs_
        |> map List.head
        |> map (Maybe.withDefault 0)



-- numberOfArgs : Parser Int
-- numberOfArgs =
--   let
--     listOfIntegers = many numberOfArgs_
--    in
--      if listOfIntegers ==  [] then
--        0
--      else
--        (List.head listOfIntegers) |> Maybe.withDefault 0


{-| Parse the macro keyword followed by
zero or more optional follwed by zero or more more eventual nominnees.
-}
macro : Parser () -> Parser LatexExpression
macro wsParser =
    --  "macro" <|
    succeed Macro
        |= macroName
        |= itemList optionalArg
        |= itemList arg
        |. wsParser


{-| Use to parse arguments for macros
-}
optionalArg : Parser LatexExpression
optionalArg =
    -- inContext "optionalArg" <|
    succeed identity
        |. symbol "["
        |= itemList (oneOf [ optionArgWords, inlineMath PH.spaces ])
        |. symbol "]"
        |> map LatexList


{-| Use to parse arguments for macros
-}
arg : Parser LatexExpression
arg =
    succeed identity
        |. symbol "{"
        |= itemList (oneOf [ macroArgWords, inlineMath PH.spaces, lazy (\_ -> macro PH.spaces) ])
        |. symbol "}"
        |> map LatexList


macroName : Parser String
macroName =
    variable
        { start = \c -> c == '\\'
        , inner = \c -> Char.isAlphaNum c || c == '*'
        , reserved = Set.fromList [ "\\begin", "\\end", "\\item", "\\bibitem" ]
        }
        |> map (String.dropLeft 1)


{-| The smacro parser assumes that the text to be
parsed forms a single paragraph
-}
smacro : Parser LatexExpression
smacro =
    succeed SMacro
        |= smacroName
        |= itemList optionalArg
        |= itemList arg
        |= lazy (\_ -> latexList)


smacroName : Parser String
smacroName =
    variable
        { start = \c -> c == '\\'
        , inner = \c -> Char.isAlphaNum c
        , reserved = Set.fromList [ "\\begin", "\\end", "\\item" ]
        }
        |> map (String.dropLeft 1)



{- Latex List and Expression -}
{- MATHEMATICAL TEXT -}


inlineMath : Parser () -> Parser LatexExpression
inlineMath wsParser =
    succeed InlineMath
        |. symbol "$"
        |= parseToSymbol "$"
        |. wsParser


displayMathDollar : Parser LatexExpression
displayMathDollar =
    -- inContext "display math $$" <|
    succeed DisplayMath
        |. PH.spaces
        |. symbol "$$"
        |= parseToSymbol "$$"
        |. ws


displayMathBrackets : Parser LatexExpression
displayMathBrackets =
    -- inContext "display math brackets" <|
    succeed DisplayMath
        |. PH.spaces
        |. symbol "\\["
        |= parseToSymbol "\\]"
        |. ws



{- ENVIRONMENTS -}


{-| Capture the name of the environment in
a \begin{ENV} ... \end{ENV}
pair
-}
envName : Parser String
envName =
    --  inContext "envName" <|
    succeed identity
        |. PH.spaces
        |. symbol "\\begin{"
        |= parseToSymbol "}"


{-| Use to parse begin ... end blocks
-}
endWord : Parser String
endWord =
    succeed identity
        |. PH.spaces
        |. symbol "\\end{"
        |= parseToSymbol "}"
        |. ws


environment : Parser LatexExpression
environment =
    envName |> andThen environmentOfType


environmentOfType : String -> Parser LatexExpression
environmentOfType envType =
    let
        theEndWord =
            "\\end{" ++ envType ++ "}"

        envKind =
            if List.member envType [ "equation", "align", "eqnarray", "verbatim", "listing", "verse" ] then
                "passThrough"
            else
                envType
    in
        environmentParser envKind theEndWord envType



{- DISPATCHER AND SUBPARSERS -}


environmentParser : String -> String -> String -> Parser LatexExpression
environmentParser envKind theEndWord envType =
    case Dict.get envKind parseEnvironmentDict of
        Just p ->
            p theEndWord envType

        Nothing ->
            standardEnvironmentBody theEndWord envType


parseEnvironmentDict : Dict.Dict String (String -> String -> Parser LatexExpression)
parseEnvironmentDict =
    Dict.fromList
        [ ( "enumerate", \endWoord envType -> itemEnvironmentBody endWoord envType )
        , ( "itemize", \endWoord envType -> itemEnvironmentBody endWoord envType )
        , ( "thebibliography", \endWoord envType -> biblioEnvironmentBody endWoord envType )
        , ( "tabular", \endWoord envType -> tabularEnvironmentBody endWoord envType )
        , ( "passThrough", \endWoord envType -> passThroughBody endWoord envType )
        ]



-- Environment String (List LatexExpression) LatexExpression -- Environment name optArgs body


standardEnvironmentBody : String -> String -> Parser LatexExpression
standardEnvironmentBody endWoord envType =
    succeed (Environment envType)
        |. ws
        |= itemList optionalArg
        |. ws
        |= (nonEmptyItemList latexExpression |> map LatexList)
        |. ws
        |. symbol endWoord
        |. ws


{-| The body of the environment is parsed as an LXString.
This parser is used for envronments whose body is to be
passed to MathJax for processing and also for the verbatim
environment.
-}
passThroughBody : String -> String -> Parser LatexExpression
passThroughBody endWoord envType =
    --  inContext "passThroughBody" <|
    succeed identity
        |= parseToSymbol endWoord
        |. ws
        |> map LXString
        |> map (Environment envType [])



{- ITEMIZED LISTS -}


itemEnvironmentBody : String -> String -> Parser LatexExpression
itemEnvironmentBody endWoord envType =
    ---  inContext "itemEnvironmentBody" <|
    succeed identity
        |. ws
        |= itemList (oneOf [ item, lazy (\_ -> environment) ])
        |. ws
        |. symbol endWoord
        |. ws
        |> map LatexList
        |> map (Environment envType [])


biblioEnvironmentBody : String -> String -> Parser LatexExpression
biblioEnvironmentBody endWoord envType =
    ---  inContext "itemEnvironmentBody" <|
    succeed identity
        |. ws
        |= itemList smacro
        |. ws
        |. symbol endWoord
        |. ws
        |> map LatexList
        |> map (Environment envType [])


biblioExample =
    """
\\begin{thebibliography}

\\bibitem{X} ABCD

\\bibitem{Y} EFGH

\\end{thebibliography}
"""


item : Parser LatexExpression
item =
    ---  inContext "item" <|
    succeed identity
        |. PH.spaces
        |. symbol "\\item"
        |. symbol " "
        |. PH.spaces
        |= itemList (oneOf [ words, inlineMath PH.ws, macro PH.ws ])
        |. ws
        |> map (\x -> Item 1 (LatexList x))



{- TABLES -}


tabularEnvironmentBody : String -> String -> Parser LatexExpression
tabularEnvironmentBody endWoord envType =
    -- inContext "tabularEnvironmentBody" <|
    succeed (Environment envType)
        |. ws
        |= itemList arg
        |= tableBody
        |. ws
        |. symbol endWoord
        |. ws


tableBody : Parser LatexExpression
tableBody =
    --  inContext "tableBody" <|
    succeed identity
        --|. repeat zeroOrMore arg
        |. ws
        |= nonEmptyItemList tableRow
        |> map LatexList


tableRow : Parser LatexExpression
tableRow =
    --- inContext "tableRow" <|
    succeed identity
        |. PH.spaces
        |= andThen (\c -> tableCellHelp [ c ]) tableCell
        |. PH.spaces
        |. oneOf [ symbol "\n", symbol "\\\\\n" ]
        |> map LatexList



-- ###


tableCell : Parser LatexExpression
tableCell =
    -- inContext "tableCell" <|
    succeed identity
        |= oneOf [ displayMathBrackets, macro PH.ws, displayMathDollar, inlineMath PH.ws, tableCellWords ]


tableCellHelp : List LatexExpression -> Parser (List LatexExpression)
tableCellHelp revCells =
    --  inContext "tableCellHelp" <|
    oneOf
        [ nextCell
            |> andThen (\c -> tableCellHelp (c :: revCells))
        , succeed (List.reverse revCells)
        ]


nextCell : Parser LatexExpression
nextCell =
    --  inContext "nextCell" <|
    -- (delayedCommit PH.spaces <|
    succeed identity
        |. symbol "&"
        |. PH.spaces
        |= tableCell



--)
