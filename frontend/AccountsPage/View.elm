module AccountsPage.View exposing (..)

import Dict exposing (Dict)
import Html as Html exposing (Html, div, ul, li, text)
import Html.Events exposing (onClick)
import Html.App as Html
import String

import AccountsPage.Model exposing (..)
import Common exposing (..)

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

transactionDetail : List Transaction -> Html a
transactionDetail trans = div [] (List.map transactionToDiv trans)

accountDiv id = div [onClick (ToggleShowTransactions id)]

accountDataToHtml : Maybe AccountId -> Maybe (List Transaction) -> (AccountId, Account) -> Html Action
accountDataToHtml mAccount mTransactions (id, acct) =
    let accountText = accountToText id acct
    in case (mAccount == Just id, mTransactions) of
    (True, Just trans) -> accountDiv id [accountText, transactionDetail trans]
    _ -> accountDiv id [accountText]


view : Model -> Html Action
view model = div []
    (List.map (accountDataToHtml model.inspectedAccount model.accountTransactions) (Dict.toList model.accounts))
