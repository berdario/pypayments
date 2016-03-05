module View where

import Dict exposing (Dict)
import Html exposing (Html, body, nav, div, select, option, input, button, ul, li, text)
import Html.Events exposing (onClick, targetValue, on)
import Html.Attributes as Attr exposing (style, type', name)
import Json.Decode as Json
import String

import Model exposing (..)

view : Signal.Address Action -> Model -> Html
view address model = body []
    [navbar address model
    ,case model.currentPage of
        Transactions -> viewTransactions address model
        Pay -> viewPaymentForm address model]
    

navbar : Signal.Address Action -> Model -> Html
navbar address model = nav []
    [ul []
        [li [onClick address (SetActivePage Transactions)] [text "Transactions"]
        ,li [onClick address (SetActivePage Pay)] [text "Make a payment"]]]

transactionToDiv t = div []
    [text (String.concat
        ["source: ", toString t.source
        ," recipient: ", toString t.recipient
        ," amount: ", toString t.amount])]
        
accountToText id {name, email, balance} =
    text (String.concat
        ["id: ", toString id
        ," name: ", name
        ," email: ", email
        ," balance: ", toString balance])

transactionDetail : List Transaction -> Html
transactionDetail trans = div [] (List.map transactionToDiv trans)

accountDiv address id = div [onClick address (ToggleShowTransactions id)]
    
accountDataToHtml : Signal.Address Action -> Maybe AccountId -> Maybe (List Transaction) -> (AccountId, Account) -> Html
accountDataToHtml address mAccount mTransactions (id, acct) =
    let accountText = accountToText id acct
    in case (mAccount == Just id, mTransactions) of
    (True, Just trans) -> accountDiv address id [accountText, transactionDetail trans]
    _ -> accountDiv address id [accountText]
    
    
viewTransactions : Signal.Address Action -> Model -> Html
viewTransactions address model = div []
    (List.map (accountDataToHtml address model.inspectedAccount model.accountTransactions) (Dict.toList model.accounts))

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

viewPaymentForm : Signal.Address Action -> Model -> Html
viewPaymentForm address model = div []
    [lastTransactionHtml model.lastTransaction
    ,select [onChange address SetSource] (List.map idOption (Dict.keys model.accounts))
    ,input [onInput address SetAmount, type' "number", Attr.min "0", Attr.max "1000", name "amount"] []
    ,select [onChange address SetRecipient] (List.map idOption (Dict.keys model.accounts))
    ,button [onClick address DoPayment] [text "transfer money"]]
