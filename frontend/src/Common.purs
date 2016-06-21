module Common where

import Prelude
import Data.Either (Either(..), either)
import Data.Foreign.Class (class IsForeign)
import Data.Foreign.Generic (readGeneric, defaultOptions)
import Data.Foldable (intercalate)
import Data.Generic (Generic)
import Data.Maybe (Maybe(..))

import Halogen (HalogenEffects)
import Network.HTTP.Affjax (AJAX)


type AppEffects eff = HalogenEffects (ajax :: AJAX | eff)

type AccountId = Int
newtype Account = Account {name:: String, email:: String, balance:: Number}
newtype Transaction = Transaction {source:: AccountId, recipient:: AccountId, amount:: Number}

derive instance genericAccount :: Generic Account
derive instance genericTransaction :: Generic Transaction

instance foreignAccount :: IsForeign Account where
    read = readGeneric defaultOptions{unwrapNewtypes=true}

instance foreignTransaction :: IsForeign Transaction where
    read = readGeneric defaultOptions{unwrapNewtypes=true}

toMaybe :: forall a b. Either a b -> Maybe b
toMaybe = either (const Nothing) Just

baseUrl = "http://localhost:8082"

accountsUrl = baseUrl <> "/accounts"

param :: forall a. Show a => String -> a -> String
param key value = key <> "=" <> show value

transactionsUrl id = baseUrl <> "/transactions?" <> param "account_id" id

payUrl source dest amount = baseUrl <> "/pay?" <>
    intercalate "&" [
          param "source" source
        , param "recipient" dest
        , param "amount" amount]