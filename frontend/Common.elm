module Common exposing (..)

import Json.Decode as Json

type alias AccountId = Int
type alias Transaction = {source: AccountId, recipient: AccountId, amount: Float}

-- https://github.com/elm-lang/http/issues/10

baseUrl = "http://localhost:8000"

accountsUrl = baseUrl ++ "/accounts"

transactionsUrl id = baseUrl ++ "/transactions?account_id=" ++ toString id

payUrl source dest amount = baseUrl ++ "/pay?source=" ++ toString source
    ++ "recipient" ++ toString dest
    ++ "amount" ++ toString amount


customDecoder decoder toResult =
    Json.andThen
             (\a ->
                   case toResult a of
                      Ok b -> Json.succeed b
                      Err err -> Json.fail err
             )
    decoder
