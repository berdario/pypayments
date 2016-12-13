module AccountsPage.Api exposing (..)

import Dict exposing (Dict)
import Http
import Json.Decode as Json exposing (field)
import String
import Task

import AccountsPage.Model exposing (..)
import Common exposing (..)

keyToInt : (String, a) -> Result String (Int, a)
keyToInt (s, x) = case String.toInt s of
    (Ok n) -> Ok (n, x)
    (Err e) -> Err e

resultSequence : List (Result x a) -> Result x (List a)
resultSequence xs = case xs of
    [] -> Ok []
    result :: rest -> Result.map2 (::) result (resultSequence rest)


kvPairsToIntDict : List (String, a) -> Result String (Dict Int a)
kvPairsToIntDict xs = Result.map Dict.fromList (resultSequence (List.map keyToInt xs))

intDict : Json.Decoder a -> Json.Decoder (Dict Int a)
intDict x = customDecoder (Json.keyValuePairs x) kvPairsToIntDict

decodeAccounts : Json.Decoder (Dict AccountId Account)
decodeAccounts = intDict decodeAccount

decodeAccount : Json.Decoder Account
decodeAccount = Json.map3 Account
    (field "name" Json.string )
    (field "email" Json.string )
    (field "balance" Json.float )

decodeTransaction : Json.Decoder Transaction
decodeTransaction = Json.map3 Transaction
    (field "source_id" Json.int )
    (field "recipient_id" Json.int )
    (field "amount" Json.float )

decodeTransactions : Json.Decoder (List Transaction)
decodeTransactions = Json.list decodeTransaction


accounts = Http.get accountsUrl decodeAccounts
    |> Http.send (FetchedAccounts << Result.toMaybe)


accountTransactions account_id =
    Http.get (transactionsUrl account_id) decodeTransactions
    |> Http.send (FetchedTransactions << Result.toMaybe)
