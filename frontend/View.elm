module View where

import Dict exposing (Dict)
import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (style)
import Json.Decode as Json
import String

import Model exposing (..)
import Update exposing (Action(..))

view : Signal.Address Action -> Model -> Html.Html
view address model = Html.body []
    [navbar address model
    ,case model.currentPage of
        Transactions -> viewTransactions address model
        Pay -> viewPaymentForm address model]
    

navbar : Signal.Address Action -> Model -> Html.Html
navbar address model = Html.nav []
    [Html.ul []
        [Html.li [onClick address (SetActivePage Transactions)] [Html.text "Transactions"]
        ,Html.li [onClick address (SetActivePage Pay)] [Html.text "Make a payment"]]]

transactionToDiv t = Html.div []
    [Html.text (String.concat
        ["source: ", toString t.source
        ," recipient: ", toString t.recipient
        ," amount: ", toString t.amount])]
        
accountToText id {name, email, balance} =
    Html.text (String.concat
        ["id: ", toString id
        ," name: ", name
        ," email: ", email
        ," balance: ", toString balance])

transactionDetail : List Transaction -> Html.Html
transactionDetail trans = Html.div [] (List.map transactionToDiv trans)

accountDiv address id = Html.div [Html.Events.onClick address (ToggleShowTransactions id)]
    
accountDataToHtml : Signal.Address Action -> Maybe AccountId -> Maybe (List Transaction) -> (AccountId, Account) -> Html.Html
accountDataToHtml address mAccount mTransactions (id, acct) =
    let accountText = accountToText id acct
    in case (mAccount == Just id, mTransactions) of
    (True, Just trans) -> accountDiv address id [accountText, transactionDetail trans]
    _ -> accountDiv address id [accountText]
    
    
viewTransactions : Signal.Address Action -> Model -> Html.Html
viewTransactions address model = Html.div []
    (List.map (accountDataToHtml address model.inspectedAccount model.accountTransactions) (Dict.toList model.accounts))

targetInt = Json.customDecoder  Html.Events.targetValue String.toInt
targetFloat = Json.customDecoder  Html.Events.targetValue String.toFloat

option id = Html.option [] [Html.text (toString id)]
onChange address actionConstructor  = Html.Events.on "change" targetInt (\a -> Signal.message address (actionConstructor a))
onInput address actionConstructor = Html.Events.on "input" targetFloat (\a -> Signal.message address (actionConstructor a))

lastTransactionHtml lastOutcome =
    let redbg = Html.Attributes.style [("backgroundColor", "red")]
    in case lastOutcome of
        Nothing -> Html.div [] []
        Just True -> Html.div [] [Html.text "The last transaction was successful"]
        Just False -> Html.div [redbg] [Html.text "The last transaction was invalid, no changes have been applied"]

viewPaymentForm : Signal.Address Action -> Model -> Html.Html
viewPaymentForm address model = Html.div []
    [lastTransactionHtml model.lastTransaction
    ,Html.select [onChange address SetSource] (List.map option (Dict.keys model.accounts))
    ,Html.input [onInput address SetAmount, Html.Attributes.type' "number", Html.Attributes.min "0", Html.Attributes.max "1000", Html.Attributes.name "amount"] []
    ,Html.select [onChange address SetRecipient] (List.map option (Dict.keys model.accounts))
    ,Html.button [Html.Events.onClick address DoPayment] [Html.text "transfer money"]]
