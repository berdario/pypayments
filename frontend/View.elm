module View where

import Dict exposing (Dict)
import Html exposing (Html, body, nav, ul, li, text)
import Html.Events exposing (onClick)

import Model exposing (..)
import AccountsPage.View as Accounts
import PaymentPage.View as Payment

view : Signal.Address Action -> Model -> Html
view address model = body []
    [navbar address model
    ,case model.currentPage of
        Accounts -> Accounts.view (Signal.forwardTo address AccountsAction) model.accounts
        Pay -> Payment.view (Signal.forwardTo address PaymentAction) model.payment (Dict.keys model.accounts.accounts)]
    

navbar : Signal.Address Action -> Model -> Html
navbar address model = nav []
    [ul []
        [li [onClick address (SetActivePage Accounts)] [text "Transactions"]
        ,li [onClick address (SetActivePage Pay)] [text "Make a payment"]]]
