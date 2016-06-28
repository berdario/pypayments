module Pay where

import Prelude

import Control.Monad.Aff (Aff, later')
import Control.Monad.Aff.Free (Affable)
import Control.Monad.Free (Free)
import Data.Maybe (Maybe(..))
import Data.Int (fromString)
import Data.List as List
import Global (readFloat)

import CSS.Background (backgroundColor)
import CSS.Color (red)
import Halogen
import Halogen.Query (Action, action)
import Halogen.HTML.Indexed as H
import Halogen.HTML.CSS.Indexed (style)
import Halogen.HTML.Events.Indexed as E
import Halogen.HTML.Properties.Indexed as P
import Halogen.HTML.Properties.Indexed.ARIA as A
import Network.HTTP.Affjax (AJAX, post)
import Network.HTTP.StatusCode (StatusCode(..))

import Common

data TransactionOutcome = Success | Fail

type State =
    { newTransaction :: Transaction
    , lastTransaction :: Maybe TransactionOutcome
    , accounts :: List.List AccountId
    }

data Query a
    = SetSource AccountId a
    | SetRecipient AccountId a
    | SetAmount Number a
    | SetAccounts (List.List AccountId) a
    | DoPayment a

data Slot = Slot
derive instance eqSlot :: Eq Slot
derive instance ordSlot :: Ord Slot

init :: State
init = {newTransaction: Transaction {source_id: 1, recipient_id: 1, amount: 0.0}, lastTransaction: Nothing, accounts: List.Nil}

idOption id = H.option_ [H.text (show id)]

lastTransactionHtml lastOutcome =
    let redbg = style $ backgroundColor red
    in case lastOutcome of
        Nothing -> H.div_ []
        Just Success -> H.div_ [H.text "The last transaction was successful"]
        Just Fail -> H.div [redbg] [H.text "The last transaction was invalid, no changes have been applied"]

intInput f = pure <<< map (action <<< f) <<< fromString
numInput f s = pure $ Just $ action $ f $ readFloat s

payComponent :: forall eff. Component State Query (Aff (AppEffects eff))
payComponent = component { render, eval }
    where

    render :: State -> ComponentHTML Query
    render {lastTransaction, accounts} = H.div_
        [ lastTransactionHtml lastTransaction
        , H.select [E.onValueChange (intInput SetSource)] $ List.toUnfoldable (map idOption accounts)
        , H.input  [E.onValueInput  (numInput SetAmount), P.inputType P.InputNumber, A.valueMin "0", A.valueMax "1000", P.name "amount"]
        , H.select [E.onValueChange (intInput SetRecipient)] $ List.toUnfoldable (map idOption accounts)
        , H.button [E.onClick  (E.input_ DoPayment)] [H.text "transfer money"]]

    eval :: Natural Query (ComponentDSL State Query (Aff (AppEffects eff)))
    eval (SetSource id next) = do
        Transaction t <- gets _.newTransaction
        modify (_{newTransaction=Transaction t{source_id=id}})
        pure next
    eval (SetRecipient id next) = do
        Transaction t <- gets _.newTransaction
        modify (_{newTransaction=Transaction t{recipient_id=id}})
        pure next
    eval (SetAmount amount next) = do
        Transaction t <- gets _.newTransaction
        modify (_{newTransaction=Transaction t{amount=amount}})
        pure next
    eval (SetAccounts accounts next) = do
        modify _{accounts=accounts}
        pure next
    eval (DoPayment next) = do
        transaction <- gets _.newTransaction
        lastOutcome <- fromAff $ pay transaction
        modify (_{lastTransaction=Just lastOutcome})
        fromAff $ sleep 3000
        -- mapF (map $ later' 3000) get
        modify (_{lastTransaction=Nothing})
        pure next

sleep :: forall eff. Int -> Aff (AppEffects eff) Unit
sleep ms = later' ms $ pure unit

outcome :: StatusCode -> TransactionOutcome
outcome (StatusCode x) | 200 <= x && x < 300 = Success
outcome _ = Fail

pay :: forall eff. Transaction -> Aff (ajax :: AJAX | eff) TransactionOutcome
pay (Transaction {source_id, recipient_id, amount}) = do
    result <- post (payUrl source_id recipient_id amount) unit
    return (result.response :: Unit)
    return $ outcome result.status

