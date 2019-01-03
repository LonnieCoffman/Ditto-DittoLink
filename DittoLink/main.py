import os
import json
import oandapyV20
import oandapyV20.endpoints.accounts as accounts
from oandapyV20.exceptions import V20Error
import functions as bridge
import time, datetime
import configparser
import msvcrt

alive_timer = 1

def update_data(token, filepath, first_account_id, second_account_id, live_trading):
    bridge.update_account(token, filepath, first_account_id, second_account_id, live_trading)
    bridge.update_positions(token, filepath, first_account_id, second_account_id, live_trading)
    bridge.update_trade_data(token, filepath, first_account_id, second_account_id, live_trading)
    return

def remove_files(filepath, fn):
    os.remove(filepath+"\\\\"+fn)
    bridge.delete_lock_file(filepath)
    return

# if config.ini file does not exist, create a blank one and exit.
try:
    if not os.path.isfile("config.ini"):
        file = open("config.ini","w")
        file.write("[settings]\nMT4DataFolder = ")
        file.close()
        print("Config file recreated: Add MT4 Data Folder location and rerun DittoLink.")
        print("Press any key to exit")
        while(True):
            if msvcrt.kbhit():
                exit()
except Exception as e:
    print(e)
    exit()

# parse filepath to MT4 Data Folder
path = configparser.ConfigParser()
path.sections()
path.read('config.ini')
filefolder = str(path['settings']['MT4DataFolder']).replace("\\","\\\\")+"\\\\mql4\\\\Files"
try:
    if not os.path.isdir(filefolder):
        print("MT4 Data Folder does not exist. Please check your path and rerun DittoLink.")
        print("Press any key to exit")
        while(True):
            if msvcrt.kbhit():
                exit()
except Exception as e:
    print(e)
    exit()

# if Ditto folder does not exist then create it
filepath = str(path['settings']['MT4DataFolder']).replace("\\","\\\\")+"\\\\mql4\\\\Files\\\\Ditto\\\\"
try:
    if not os.path.isdir(filepath):
        try:
            os.mkdir(filepath)
        except OSError:
            print("Error encountered creating Ditto folder. Run the Ditto EA and then rerun DittoLink.")
            print("Press any key to exit")
            while(True):
                if msvcrt.kbhit():
                    exit()
except Exception as e:
    print(e)
    exit()

firstRun = True

# run until exited
while True:

    # loop through directories
    for root, dirs, files in os.walk(filepath):
        for dir in dirs:
            
            path = root+dir
            
            # check if config file exists
            if os.path.isfile(path+"\\\\config.ini"):
                
                # config file exists, so parse it.
                expert = configparser.ConfigParser()
                expert.sections()
                expert.read(path+"\\\\config.ini")

                # assign variables
                first_account_id = str(expert['settings']['first_account_id'])
                second_account_id = str(expert['settings']['second_account_id'])
                access_token = str(expert['settings']['token'])
                live_trading = True if expert['settings']['live_trading'] == "True" else False

                # dual account?
                if (second_account_id == ""):
                    dual_account = False
                else:
                    dual_account = True

                # set API client and token
                if (live_trading):
                    client = oandapyV20.API(access_token=access_token, environment='live')
                else:
                    client = oandapyV20.API(access_token=access_token, environment='practice')

                # create alive check file
                if (datetime.datetime.now().second % alive_timer == 0):
                    bridge.alive_check(path)
                
                # on first run update data
                if (firstRun):
                    update_data(access_token, path, first_account_id, second_account_id, live_trading)

                # if account or trade files do not exist then create them.
                tradeFileExists = False
                accountFileExists = False

                for fn in os.listdir(path+"\\\\"): # loop through files in directory
                    if 'FXtTrades.txt' in fn:
                        tradeFileExists = True
                    elif dual_account and 'account-short.txt' in fn:
                        accountFileExists = True
                    elif not dual_account and 'account-combined.txt' in fn:
                        accountFileExists = True
                
                # create missing files
                if not tradeFileExists or not accountFileExists:
                    update_data(access_token, path, first_account_id, second_account_id, live_trading)

                # # watch for files
                for fn in os.listdir(path+"\\\\"): # loop through files in directory
                    if 'updateTradeData' in fn:
                        bridge.create_lock_file(path)
                        bridge.update_trade_data(access_token, path, first_account_id, second_account_id, live_trading)
                        remove_files(path, fn)
                    elif 'openmarket-' in fn:
                        bridge.create_lock_file(path)
                        bridge.open_trade(access_token, path, fn, first_account_id, second_account_id, live_trading)
                        update_data(access_token, path, first_account_id, second_account_id, live_trading)
                        remove_files(path, fn)
                    elif 'closeTrade-' in fn:
                        bridge.create_lock_file(path)
                        bridge.close_trade(access_token, path, fn, first_account_id, second_account_id, live_trading)
                        update_data(access_token, path, first_account_id, second_account_id, live_trading)
                        remove_files(path, fn)
                    elif 'closePosition-' in fn:
                        bridge.create_lock_file(path)
                        bridge.close_position(access_token, path, fn, first_account_id, second_account_id, live_trading)
                        update_data(access_token, path, first_account_id, second_account_id, live_trading)
                        remove_files(path, fn)

    firstRun = False
                

    time.sleep(1)
