# Install/run

in a Python3 virtualenv

    pip install -r requirements.txt
    
Run the tests:

    py.test

Run the server:

    hug -f payments.py
    
    
There're 3 api endpoints:
    
    http://localhost:8000/
    
This will return all the accounts (with their name, email, balance)
    
    http://localhost:8000/account?account_id=2
    
This will return all the transactions involving a single account    
    
    http://localhost:8000/pay?source=1&recipient=2&amount=1
    
This will make a payment, while respecting the constraints (source and recipient have to exist, no negative balance)