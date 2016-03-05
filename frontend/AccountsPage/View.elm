module AccountsPage.View where

import Dict exposing (Dict)
import Html exposing (Html, div, ul, li, text)
import Html.Events exposing (onClick)
import String

import AccountsPage.Model exposing (..)

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
    
    
view : Signal.Address Action -> Model -> Html
view address model = div []
    (List.map (accountDataToHtml address model.inspectedAccount model.accountTransactions) (Dict.toList model.accounts))
