module MiniLatex.RenderToLatex
    exposing
        ( render
        , renderBackToLatex
        , renderBackToLatexTest
        , renderBackToLatexTestModSpace
        , renderLatexList
        )

{-| s


# API

@docs render, renderBackToLatex, renderBackToLatexTest, renderBackToLatexTestModSpace, renderLatexList

-}

import MiniLatex.ErrorMessages as ErrorMessages
import MiniLatex.JoinStrings as JoinStrings
import MiniLatex.Paragraph
import MiniLatex.Parser exposing (LatexExpression(..), defaultLatexList, latexList)
import Parser
import MiniLatex.Utility as Utility


{-| parse a stringg and render it back into Latex
-}
renderBackToLatex : String -> String
renderBackToLatex str =
    str
        |> MiniLatex.Paragraph.logicalParagraphify
        |> List.map MiniLatex.Parser.parse
        |> List.map renderLatexList
        |> List.foldl (\par acc -> acc ++ par ++ "\n\n") ""


{-| return true if a string rendered back to latex is the
original string.
-}
renderBackToLatexTest : String -> Bool
renderBackToLatexTest str =
    str == renderBackToLatex str


{-| return true if a string rendered back to latex is the
original string, but ignore spaces in the compariosn.
-}
renderBackToLatexTestModSpace : String -> Bool
renderBackToLatexTestModSpace str =
    (str |> String.replace " " "") == (renderBackToLatex str |> String.replace " " "")


{-| Redner a string into LaTeX
-}
render : LatexExpression -> String
render latexExpression =
    case latexExpression of
        Comment str ->
            renderComment str

        Macro name optArgs args ->
            renderMacro name optArgs args

        SMacro name optArgs args le ->
            renderSMacro name optArgs args le

        Item level latexExpression_ ->
            renderItem level latexExpression_

        InlineMath str ->
            " $" ++ str ++ "$"

        DisplayMath str ->
            "$$" ++ str ++ "$$"

        Environment name args body ->
            renderEnvironment name args body

        LatexList args ->
            renderLatexList args

        LXString str ->
            str

        LXError error ->
            List.map ErrorMessages.renderError error |> String.join "; "


{-| Render a list of LatexExpressions
-}
renderLatexList : List LatexExpression -> String
renderLatexList args =
    args |> List.map render |> List.foldl (\item acc -> acc ++ item) ""



-- JoinStrings.joinList


renderArgList : List LatexExpression -> String
renderArgList args =
    args |> List.map render |> List.map (\x -> "{" ++ x ++ "}") |> String.join ""


renderOptArgList : List LatexExpression -> String
renderOptArgList args =
    args |> List.map render |> List.map (\x -> "[" ++ x ++ "]") |> String.join ""


renderItem : Int -> LatexExpression -> String
renderItem level latexExpression =
    "\\item " ++ render latexExpression ++ "\n\n"


renderComment : String -> String
renderComment str =
    "% " ++ str ++ "\n"


renderEnvironment : String -> List LatexExpression -> LatexExpression -> String
renderEnvironment name args body =
    "\\begin{" ++ name ++ "}" ++ renderArgList args ++ "\n" ++ render body ++ "\n\\end{" ++ name ++ "}\n"


renderMacro : String -> List LatexExpression -> List LatexExpression -> String
renderMacro name optArgs args =
    " \\" ++ name ++ renderOptArgList optArgs ++ renderArgList args


renderSMacro : String -> List LatexExpression -> List LatexExpression -> LatexExpression -> String
renderSMacro name optArgs args le =
    " \\" ++ name ++ renderOptArgList optArgs ++ renderArgList args ++ " " ++ render le ++ "\n\n"
