module Api where

import Dict exposing (Dict)
import Effects exposing (Effects, Never)
import Http
import Json.Decode as Json exposing ((:=))
import String
import Task

import Model exposing (..)


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
intDict x = Json.customDecoder (Json.keyValuePairs x) kvPairsToIntDict

decodeAccounts : Json.Decoder (Dict AccountId Account)
decodeAccounts = intDict decodeAccount

decodeAccount : Json.Decoder Account
decodeAccount = Json.object3 Account
    ("name" := Json.string )
    ("email" := Json.string )
    ("balance" := Json.float )
    
decodeTransaction : Json.Decoder Transaction
decodeTransaction = Json.object3 Transaction
    ("source_id" := Json.int )
    ("recipient_id" := Json.int )
    ("amount" := Json.float )
    
decodeTransactions : Json.Decoder (List Transaction)
decodeTransactions = Json.list decodeTransaction


baseUrl = "http://localhost:8000" 

accountsUrl = Http.url (baseUrl ++ "/accounts") []

accountUrl id = Http.url (baseUrl ++ "/transactions") [("account_id", toString id)]

payUrl source dest amount = Http.url (baseUrl ++ "/pay")
    [("source", toString source)
    ,("recipient", toString dest)
    ,("amount", toString amount)]

    
