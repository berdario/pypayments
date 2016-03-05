module AccountsPage.Model where

import Dict exposing (Dict)

import Common exposing (..)

type alias Account = {name: String, email: String, balance: Float}

type alias Model =
    { accounts : Dict AccountId Account
    , accountTransactions : Maybe (List Transaction)
    , inspectedAccount : Maybe AccountId
    }
    
type Action
    = ToggleShowTransactions AccountId
    | FetchedAccounts (Maybe (Dict AccountId Account))
    | FetchedTransactions (Maybe (List Transaction))
    
init : Model
init = Model Dict.empty Nothing Nothing
