module Main where
import Effects exposing (Effects, Never)
import Dict exposing (Dict)
import Http
import Html
import Html.Events
import Html.Attributes
import Json.Decode as Json exposing ((:=))
import StartApp
import String
import Task



app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = []
    }
    
-- Model

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


init : (Model, Effects Action)
init =
  ( Model Dict.empty Nothing Nothing {source=0, recipient=0, amount=0} Transactions Nothing
  , accounts)

-- Update

type Action
    = SetActivePage Page
    | SetSource AccountId
    | SetRecipient AccountId
    | SetAmount Float
    | DoPayment
    | ToggleShowTransactions AccountId
    | LastTransactionOutcome Bool
    | ClearLastTransactionOutcome
    | FetchedAccounts (Maybe (Dict AccountId Account))
    | FetchedTransactions (Maybe (List Transaction))

    
updatePage : Page -> Model -> (Model, Effects Action)
updatePage page model = if model.currentPage == page
    then (model, Effects.none)
    else ({model | currentPage=page}, accounts) 

toggleInspection : AccountId -> Model -> (Model, Effects Action)
toggleInspection id model =
    case (Just id == model.inspectedAccount, model.inspectedAccount) of
        (True, _) -> ({model | inspectedAccount=Nothing}, Effects.none)
        (False, Nothing) -> ({model | inspectedAccount=Just id}, accountTransactions id)
        (False, Just _) -> ({model | inspectedAccount=Just id, accountTransactions=Nothing},
                            accountTransactions id)

delayedClear : Effects Action
delayedClear =
    Task.sleep 3000 `Task.andThen` (\_ -> Task.succeed ClearLastTransactionOutcome)
    |> Effects.task

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    (SetActivePage page) -> updatePage page model
    (SetSource id) -> let trans = model.newTransaction
                      in ({model | newTransaction={trans|source=id}}, Effects.none)
    (SetRecipient id) -> let trans = model.newTransaction
                         in ({model | newTransaction={trans|recipient=id}}, Effects.none)
    (SetAmount amount) -> let trans = model.newTransaction
                          in ({model | newTransaction={trans|amount=amount}}, Effects.none)
    DoPayment -> (model, pay model.newTransaction)
    (ToggleShowTransactions id) -> toggleInspection id model
    (LastTransactionOutcome flag) -> ({model| lastTransaction=Just flag}, delayedClear)
    ClearLastTransactionOutcome -> ({model| lastTransaction=Nothing}, Effects.none)
    (FetchedAccounts Nothing) -> (model, Effects.none)
    (FetchedTransactions Nothing) -> (model, Effects.none)
    (FetchedAccounts (Just accts)) -> ({model|accounts=accts}, Effects.none)
    (FetchedTransactions (Just trans)) -> ({model|accountTransactions=Just trans}, Effects.none)

-- View

view : Signal.Address Action -> Model -> Html.Html
view address model = Html.body []
    [navbar address model
    ,case model.currentPage of
        Transactions -> viewTransactions address model
        Pay -> viewPaymentForm address model]
    

navbar : Signal.Address Action -> Model -> Html.Html
navbar address model = Html.nav []
    [Html.ul []
        [Html.li [Html.Events.onClick address (SetActivePage Transactions)] [Html.text "Transactions"]
        ,Html.li [Html.Events.onClick address (SetActivePage Pay)] [Html.text "Make a payment"]]]

transactionToDiv t = Html.div []
    [Html.text (String.concat
        ["source: ", toString t.source
        ," recipient: ", toString t.recipient
        ," amount: ", toString t.amount])]
        
accountToText id {name, email, balance} =
    Html.text (String.concat
        ["id: ", toString id
        ," name: ", name
        ," email: ", email
        ," balance: ", toString balance])

transactionDetail : List Transaction -> Html.Html
transactionDetail trans = Html.div [] (List.map transactionToDiv trans)

accountDiv address id = Html.div [Html.Events.onClick address (ToggleShowTransactions id)]
    
accountDataToHtml : Signal.Address Action -> Maybe AccountId -> Maybe (List Transaction) -> (AccountId, Account) -> Html.Html
accountDataToHtml address mAccount mTransactions (id, acct) =
    let accountText = accountToText id acct
    in case (mAccount == Just id, mTransactions) of
    (True, Just trans) -> accountDiv address id [accountText, transactionDetail trans]
    _ -> accountDiv address id [accountText]
    
    
viewTransactions : Signal.Address Action -> Model -> Html.Html
viewTransactions address model = Html.div []
    (List.map (accountDataToHtml address model.inspectedAccount model.accountTransactions) (Dict.toList model.accounts))

targetInt = Json.customDecoder  Html.Events.targetValue String.toInt
targetFloat = Json.customDecoder  Html.Events.targetValue String.toFloat

option id = Html.option [] [Html.text (toString id)]
onChange address actionConstructor  = Html.Events.on "change" targetInt (\a -> Signal.message address (actionConstructor a))
onInput address actionConstructor = Html.Events.on "input" targetFloat (\a -> Signal.message address (actionConstructor a))

lastTransactionHtml lastOutcome =
    let redbg = Html.Attributes.style [("backgroundColor", "red")]
    in case lastOutcome of
        Nothing -> Html.div [] []
        Just True -> Html.div [] [Html.text "The last transaction was successful"]
        Just False -> Html.div [redbg] [Html.text "The last transaction was invalid, no changes have been applied"]

viewPaymentForm : Signal.Address Action -> Model -> Html.Html
viewPaymentForm address model = Html.div []
    [lastTransactionHtml model.lastTransaction
    ,Html.select [onChange address SetSource] (List.map option (Dict.keys model.accounts))
    ,Html.input [onInput address SetAmount, Html.Attributes.type' "number", Html.Attributes.min "0", Html.Attributes.max "1000", Html.Attributes.name "amount"] []
    ,Html.select [onChange address SetRecipient] (List.map option (Dict.keys model.accounts))
    ,Html.button [Html.Events.onClick address DoPayment] [Html.text "transfer money"]]

main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks


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



-- Effects

baseUrl = "http://localhost:8000" 

accountsUrl = Http.url baseUrl []

accountUrl id = Http.url (baseUrl ++ "/account") [("account_id", toString id)]

payUrl source dest amount = Http.url (baseUrl ++ "/pay")
    [("source", toString source)
    ,("recipient", toString dest)
    ,("amount", toString amount)]
    
    
    
accounts = Http.get decodeAccounts accountsUrl
    |> Task.toMaybe
    |> Task.map FetchedAccounts
    |> Effects.task


accountTransactions id =
    Http.get decodeTransactions (accountUrl id)
    |> Task.toMaybe
    |> Task.map FetchedTransactions
    |> Effects.task

pay' source dest amount = Http.post Json.value (payUrl source dest amount) Http.empty
pay {source, recipient, amount} =
    pay' source recipient amount
    |> Task.map (\_ -> LastTransactionOutcome True)
    |> flip Task.onError (\_ -> Task.succeed (LastTransactionOutcome False))
    |> Effects.task
