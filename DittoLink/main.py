import os
import ctypes
import json
import oandapyV20
import oandapyV20.endpoints.accounts as accounts
from oandapyV20.exceptions import V20Error
import functions as bridge
import time, datetime
import configparser
import msvcrt

version = "1.1.1"

#pyinstaller main.py -F -i icon.ico --path C:\Windows\SysWOW64\downlevel --hidden-import requests --hidden-import oandapyV20 --hidden-import six --hidden-import importlib

alive_timer = 1

def update_data(token, filepath, first_account_id, second_account_id, live_trading, system):
    bridge.update_account(token, filepath, first_account_id, second_account_id, live_trading, system)
    # if there is an error with the account, do not continue
    if not os.path.isfile(path+"\\\\error.txt"):
        bridge.update_positions(token, filepath, first_account_id, second_account_id, live_trading, system)
        bridge.update_trade_data(token, filepath, first_account_id, second_account_id, live_trading)
    return

def remove_files(filepath, fn):
    if os.path.isfile(filepath+"\\\\"+fn):
        os.remove(filepath+"\\\\"+fn)
    bridge.delete_lock_file(filepath)
    return
ctypes.windll.kernel32.SetConsoleTitleW("DittoLink v"+ version +" - Initializing")
#sys.stdout.write("\x1b]2;DittoLink v"+ version +"\x07")

os.system('cls')

print("")
print("DittoLink v" + version)
print("")

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

terminals = []

# parse filepath to MT4 Data Folders
path = configparser.ConfigParser()
path.sections()
path.read('config.ini')
filefolder = str(path['settings']['MT4DataFolder'])
if (filefolder == ""):
    print("You have not added any terminals. Add a path to the config.ini file and rerun DittoLink.")
    print("Press any key to exit")
    while(True):
        if msvcrt.kbhit():
            exit()
tempTerminals = filefolder.split(",")
for tempTerminal in tempTerminals:
    tempTerminal = tempTerminal.replace('"','') # remove quotes
    tempTerminal = tempTerminal.strip()         # remove any whitespace at beginning or end
    tempTerminal = tempTerminal.replace("\\","\\\\")+"\\\\mql4\\\\Files" # format string and add files folder at end
    try:
        if not os.path.isdir(tempTerminal):
            print(tempTerminal+" Does not exist please check your path and rerun DittoLink.")
            print("Press any key to exit")
            while(True):
                if msvcrt.kbhit():
                    exit()
    except Exception as e:
        print(e)
        exit()

    # if Ditto folder does not exist then create it
    try:
        if not os.path.isdir(tempTerminal+"\\\\Ditto\\\\"):
            try:
                os.mkdir(tempTerminal+"\\\\Ditto\\\\")
            except OSError:
                print("Error encountered creating Ditto folder in "+tempTerminal+".")
                print("Run the Ditto EA and then rerun DittoLink.")
                print("Press any key to exit")
                while(True):
                    if msvcrt.kbhit():
                        exit()
    except Exception as e:
        print(e)
        exit()

    # add cleaned terminal to terminals array
    terminals.append(tempTerminal+"\\\\Ditto\\\\")

firstRun = True
prevNumInstances = 0
numInstances = 0
systemNames = []
prevSystemNames = []

# run until exited
while True:

    # loop through terminals
    for terminal in terminals:

        # loop through directories
        for root, dirs, files in os.walk(terminal):
            for dir in dirs:
                
                path = root+dir

                # check if config file exists
                if os.path.isfile(path+"\\\\config.ini"):
                    
                    numInstances += 1

                    # account error, do not continue with this system
                    if not os.path.isfile(path+"\\\\error.txt"):

                        # config file exists, so parse it.
                        expert = configparser.ConfigParser()
                        expert.sections()
                        expert.read(path+"\\\\config.ini")

                        # assign variables
                        system = str(expert['settings']['system_name'])
                        first_account_id = str(expert['settings']['first_account_id'])
                        second_account_id = str(expert['settings']['second_account_id'])
                        access_token = str(expert['settings']['token'])
                        live_trading = True if expert['settings']['live_trading'] == "True" else False

                        systemNames.append(system)

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
                            update_data(access_token, path, first_account_id, second_account_id, live_trading, system)

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
                            update_data(access_token, path, first_account_id, second_account_id, live_trading, system)

                        # # watch for files
                        for fn in os.listdir(path+"\\\\"): # loop through files in directory
                            if 'updateTradeData' in fn:
                                bridge.create_lock_file(path)
                                bridge.update_trade_data(access_token, path, first_account_id, second_account_id, live_trading)
                                remove_files(path, fn)
                            elif 'openMarket-' in fn:
                                bridge.create_lock_file(path)
                                bridge.open_trade(access_token, path, fn, first_account_id, second_account_id, live_trading, system)
                                update_data(access_token, path, first_account_id, second_account_id, live_trading, system)
                                remove_files(path, fn)
                            elif 'openPending-' in fn:
                                bridge.create_lock_file(path)
                                bridge.place_pending(access_token, path, fn, first_account_id, second_account_id, live_trading, system)
                                update_data(access_token, path, first_account_id, second_account_id, live_trading, system)
                                remove_files(path, fn)
                            elif 'cancelPending-' in fn:
                                bridge.create_lock_file(path)
                                bridge.cancel_pending(access_token, path, fn, first_account_id, second_account_id, live_trading, system)
                                update_data(access_token, path, first_account_id, second_account_id, live_trading, system)
                                remove_files(path, fn)
                            elif 'closeTrade-' in fn:
                                bridge.create_lock_file(path)
                                bridge.close_trade(access_token, path, fn, first_account_id, second_account_id, live_trading, system)
                                update_data(access_token, path, first_account_id, second_account_id, live_trading, system)
                                remove_files(path, fn)
                            elif 'closePosition-' in fn:
                                bridge.create_lock_file(path)
                                bridge.close_position(access_token, path, fn, first_account_id, second_account_id, live_trading, system)
                                update_data(access_token, path, first_account_id, second_account_id, live_trading, system)
                                remove_files(path, fn)

    # display number of Ditto instances monitored
    sysNames = (', '.join(systemNames))
    if numInstances != prevNumInstances or prevSystemNames != systemNames:
        if numInstances == 1:
            ctypes.windll.kernel32.SetConsoleTitleW("DittoLink v"+ version +" - Monitoring "+ str(numInstances) +" System - "+sysNames)
        else:
            ctypes.windll.kernel32.SetConsoleTitleW("DittoLink v"+ version +" - Monitoring "+ str(numInstances) +" Systems - "+sysNames)
    
    prevNumInstances = numInstances    
    numInstances = 0
    prevSystemNames = systemNames
    systemNames = []

    firstRun = False
                

    time.sleep(1)
