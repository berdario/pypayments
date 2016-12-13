module View exposing (..)

import Dict exposing (Dict)
import Html exposing (Html, body, nav, ul, li, text)
import Html.Events exposing (onClick)
import Html

import Model exposing (..)
import AccountsPage.View as Accounts
import PaymentPage.View as Payment

view : Model -> Html Action
view model = body []
    [navbar model
    ,case model.currentPage of
        Accounts -> Html.map AccountsAction (Accounts.view model.accounts)
        Pay -> Html.map PaymentAction (Payment.view model.payment (Dict.keys model.accounts.accounts))]


navbar : Model -> Html Action
navbar model = nav []
    [ul []
        [li [onClick (SetActivePage Accounts)] [text "Transactions"]
        ,li [onClick (SetActivePage Pay)] [text "Make a payment"]]]
