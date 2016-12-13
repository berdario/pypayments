module PaymentPage.View exposing (..)

import Html exposing (Html, div, select, option, input, button, text)
import Html.Events exposing (onClick, targetValue, on)
import Html.Attributes as Attr exposing (style, type', name)
import Json.Decode as Json
import String

import Common exposing (..)
import PaymentPage.Model exposing (..)

targetInt = Json.customDecoder targetValue String.toInt
targetFloat = Json.customDecoder targetValue String.toFloat

idOption id = option [] [text (toString id)]
onChange msg = on "change" (Json.map msg targetInt)
onInput msg = on "input" (Json.map msg targetFloat)

lastTransactionHtml lastOutcome =
    let redbg = style [("backgroundColor", "red")]
    in case lastOutcome of
        Nothing -> div [] []
        Just Success -> div [] [text "The last transaction was successful"]
        Just Fail -> div [redbg] [text "The last transaction was invalid, no changes have been applied"]

view : Model -> List AccountId -> Html Action
view model accounts = div []
    [lastTransactionHtml model.lastTransaction
    ,select [onChange SetSource] (List.map idOption accounts)
    ,input [onInput SetAmount, type' "number", Attr.min "0", Attr.max "1000", name "amount"] []
    ,select [onChange SetRecipient] (List.map idOption accounts)
    ,button [onClick DoPayment] [text "transfer money"]]
