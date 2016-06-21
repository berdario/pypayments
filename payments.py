from decimal import Decimal

import hug
from falcon import HTTP_400

from model import get_all_accounts, get_account_transactions, record_payment_transaction, IntegrityError

@hug.get('/', output=hug.output_format.file)
def index():
    return 'index.html'

@hug.get('/app.js', output=hug.output_format.file)
def app():
    return 'app.js'

@hug.get('/accounts')
def main():
    def to_dict(result):
        d = dict(result)
        del d['id']
        d['balance'] = float(d['balance'])
        return d

    return {accnt.id: to_dict(accnt) for accnt in get_all_accounts()}

@hug.get('/transactions')
def account_transactions(account_id: int):
    def to_dict(result):
        d = dict(result)
        del d['id']
        d['amount'] = float(d['amount'])
        return d
        
    return [to_dict(tsct) for tsct in get_account_transactions(account_id)]


@hug.post('/pay')
def pay(source: int, recipient: int, amount: Decimal, response=None):
    try:
        record_payment_transaction(source, recipient, amount)
    except IntegrityError:
        response.status = HTTP_400

