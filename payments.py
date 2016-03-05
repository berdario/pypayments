from decimal import Decimal

import hug

from model import sqlite, accounts, transactions, update_balance                          

@hug.get('/', output=hug.output_format.file)
def index():
    return 'index.html'

@hug.get('/accounts')
def main(connection=None):
    connection = connection or sqlite.connect()
    def to_dict(result):
        d = dict(result)
        del d['id']
        d['balance'] = float(d['balance'])
        return d

    return {accnt.id: to_dict(accnt) for accnt in connection.execute(accounts.select())}


@hug.get('/transactions')
def account_transactions(account_id: int, connection=None):
    connection = connection or sqlite.connect()
    def to_dict(result):
        d = dict(result)
        del d['id']
        d['amount'] = float(d['amount'])
        return d

    acct_transactions = transactions.select().where((transactions.c.source_id == account_id) | 
                                            (transactions.c.recipient_id == account_id))
    return [to_dict(tsct) for tsct in connection.execute(acct_transactions)]


@hug.post('/pay')
def pay(source: int, recipient: int, amount: Decimal, connection=None):
    connection = connection or sqlite.connect()
    with connection.begin():
        connection.execute(update_balance(source, -amount))
        connection.execute(update_balance(recipient, +amount))
        # inserting into transactions is not only needed for /account
        # but it also checks the id validity and for the amount to be positive
        connection.execute(transactions.insert().values(source_id=source,
                                                         recipient_id=recipient,
                                                         amount=amount))

