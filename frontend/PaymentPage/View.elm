module PaymentPage.View where

import Html exposing (Html, div, select, option, input, button, text)
import Html.Events exposing (onClick, targetValue, on)
import Html.Attributes as Attr exposing (style, type', name)
import Json.Decode as Json
import String

import PaymentPage.Model exposing (..)

targetInt = Json.customDecoder targetValue String.toInt
targetFloat = Json.customDecoder targetValue String.toFloat

idOption id = option [] [text (toString id)]
onChange address actionConstructor  = on "change" targetInt (\a -> Signal.message address (actionConstructor a))
onInput address actionConstructor = on "input" targetFloat (\a -> Signal.message address (actionConstructor a))

lastTransactionHtml lastOutcome =
    let redbg = style [("backgroundColor", "red")]
    in case lastOutcome of
        Nothing -> div [] []
        Just Success -> div [] [text "The last transaction was successful"]
        Just Fail -> div [redbg] [text "The last transaction was invalid, no changes have been applied"]

view : Signal.Address Action -> Model -> List AccountId -> Html
view address model accounts = div []
    [lastTransactionHtml model.lastTransaction
    ,select [onChange address SetSource] (List.map idOption accounts)
    ,input [onInput address SetAmount, type' "number", Attr.min "0", Attr.max "1000", name "amount"] []
    ,select [onChange address SetRecipient] (List.map idOption accounts)
    ,button [onClick address DoPayment] [text "transfer money"]]
