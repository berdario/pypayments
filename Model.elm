module Model where

import Dict exposing (Dict)

type Page = Transactions | Pay
type alias AccountId = Int
type alias Account = {name: String, email: String, balance: Float}
type alias Transaction = {source: AccountId, recipient: AccountId, amount: Float}

type alias Model =
    { accounts : Dict AccountId Account
    , accountTransactions : Maybe (List Transaction)
    , inspectedAccount : Maybe AccountId
    , newTransaction : Transaction
    , currentPage : Page
    , lastTransaction : Maybe Bool
    }
