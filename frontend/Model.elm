module Model where

import Dict exposing (Dict)

type Page = Transactions | Pay
type TransactionOutcome = Success | Fail
type alias AccountId = Int
type alias Account = {name: String, email: String, balance: Float}
type alias Transaction = {source: AccountId, recipient: AccountId, amount: Float}

type alias Model =
    { accounts : Dict AccountId Account
    , accountTransactions : Maybe (List Transaction)
    , inspectedAccount : Maybe AccountId
    , newTransaction : Transaction
    , currentPage : Page
    , lastTransaction : Maybe TransactionOutcome
    }

type Action
    = SetActivePage Page
    | SetSource AccountId
    | SetRecipient AccountId
    | SetAmount Float
    | DoPayment
    | ToggleShowTransactions AccountId
    | LastTransactionOutcome TransactionOutcome
    | ClearLastTransactionOutcome
    | FetchedAccounts (Maybe (Dict AccountId Account))
    | FetchedTransactions (Maybe (List Transaction))
