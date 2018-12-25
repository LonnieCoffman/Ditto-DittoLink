import os
import json
import oandapyV20
import oandapyV20.endpoints.accounts as accounts
from oandapyV20.exceptions import V20Error
import functions as bridge
import time, datetime
import static

accountID = static.short_account_id
access_token = static.token

if (static.live_trading):
    client = oandapyV20.API(access_token=access_token, environment='live')
else:
    client = oandapyV20.API(access_token=access_token, environment='practice')

bridge.alive_check()
bridge.update_account()
bridge.update_positions()

alive_timer = 1

def update_data():
    bridge.update_account()
    bridge.update_positions()
    bridge.update_trade_data()
    return

def remove_files(fn):
    os.remove(static.filepath+fn)
    bridge.delete_lock_file()
    return

while True:

    if (datetime.datetime.now().second % alive_timer == 0): bridge.alive_check()
    
    #watch for files
    for fn in os.listdir(static.filepath): # loop through files in directory
        if 'updateTradeData' in fn:
            bridge.create_lock_file()
            bridge.update_trade_data()
            remove_files(fn)
        elif 'openmarket-' in fn:
            bridge.create_lock_file()
            bridge.open_trade(fn)
            update_data()
            remove_files(fn)
        elif 'closeTrade-' in fn:
            bridge.create_lock_file()
            bridge.close_trade(fn)
            update_data()
            remove_files(fn)
        elif 'closePosition-' in fn:
            bridge.create_lock_file()
            bridge.close_position(fn)
            update_data()
            remove_files(fn)

    time.sleep(1)
