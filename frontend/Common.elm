module Common where

import Http

type alias AccountId = Int
type alias Transaction = {source: AccountId, recipient: AccountId, amount: Float}


baseUrl = "http://localhost:8000" 

accountsUrl = Http.url (baseUrl ++ "/accounts") []

transactionsUrl id = Http.url (baseUrl ++ "/transactions") [("account_id", toString id)]

payUrl source dest amount = Http.url (baseUrl ++ "/pay")
    [("source", toString source)
    ,("recipient", toString dest)
    ,("amount", toString amount)]
