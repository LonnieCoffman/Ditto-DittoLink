import os
import json
import oandapyV20
import oandapyV20.endpoints.accounts as accounts
import oandapyV20.endpoints.positions as positions
import oandapyV20.endpoints.trades as trades
import oandapyV20.endpoints.orders as orders
from oandapyV20.contrib.requests import MarketOrderRequest
from oandapyV20.contrib.requests import ClientExtensions
from oandapyV20.contrib.requests import TakeProfitDetails, StopLossDetails
from oandapyV20.exceptions import V20Error
from datetime import datetime, timedelta
from collections import defaultdict
import static

CLOSE_TRADE_MESSAGE = '''TRADE CLOSED:  ===============================
                  Time:  {time} EST
                  Pair:  {instrument}
                  Units: {units} ({direction})
                  FXtID: {fxtid}
                  MT4ID: {mt4id}
                  P/L:  ${pl}
                  ==============================='''
CLOSE_POSITION_MESSAGE = '''POSITION CLOSED:  ===============================
                  Time:  {time} EST
                  Pair:  {instrument}
                  Units: {units} ({direction})
                  P/L:  ${pl}
                  ==============================='''
CLOSE_PARTIAL_MESSAGE = '''PARTIAL CLOSE:  ===============================
                  Time:  {time} EST
                  Pair:  {instrument}
                  Units: {units} ({direction})
                  P/L:  ${pl}
                  ==============================='''
OPEN_TRADE_MESSAGE = '''TRADE OPENED:  ===============================
                  Time:  {time} EST
                  Pair:  {instrument}
                  Units: {units} ({direction})
                  FXtID: {fxtid}
                  MT4ID: {mt4id}
                  ==============================='''

#######################################################
# create a lock file to prevent mt4 from accessing data
#######################################################
def create_lock_file():
    try:
        file = open(static.filepath+"bridge_lock","w")
        file.close()
    except Exception as e:
        print(e)
    return

############################
# delete the above lock file
############################
def delete_lock_file():
    try:
        if os.path.isfile(static.filepath+"bridge_lock"):
            os.remove(static.filepath+"bridge_lock")
    except Exception as e:
        print(e)
    return

###############################################################################
# create an alive check file - an EA can use this to check if script is running
###############################################################################
def alive_check():
    if not is_directory_locked():
        try:
            if not os.path.isfile(static.filepath+"alive_check"):
                create_lock_file()
                file = open(static.filepath+"alive_check","w")
                file.close()
                delete_lock_file()
        except Exception as e:
            print(e)
    return

#######################################
# close all positions for an instrument
#######################################
def close_position(fn):
    if not is_directory_locked():
        try:
            _,instrument,side,numUnits = fn.split('-')

            if (numUnits == "0"):
                numUnits = "ALL"

            if (static.live_trading):
                client = oandapyV20.API(static.token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(static.token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})

            if (side == "long" or side == "both"):
                #close long positions
                r = positions.PositionClose(static.long_account_id, instrument, {"longUnits": numUnits})
                try:
                    client.request(r)
                    pl = '{:,.2f}'.format(float(r.response["longOrderFillTransaction"]["pl"]))
                    units = abs(int(r.response["longOrderFillTransaction"]["units"]))
                    time = (datetime.now() + timedelta(hours = 3)).strftime('%m/%d/%Y @ %I:%M %p')
                    if (numUnits == "ALL"):
                        print(CLOSE_POSITION_MESSAGE.format(time=time, instrument=instrument, direction = side, units=units, pl=pl))
                    else:
                        print(CLOSE_PARTIAL_MESSAGE.format(time=time, instrument=instrument, direction = side, units=units, pl=pl))
                except V20Error as err:
                    print("V20Error occurred: {}".format(err))

            if (side == "short" or side == "both"):
                #close short positions
                r = positions.PositionClose(static.short_account_id, instrument, {"shortUnits": numUnits})
                try:
                    client.request(r)
                    pl = '{:,.2f}'.format(float(r.response["shortOrderFillTransaction"]["pl"]))
                    units = abs(int(r.response["shortOrderFillTransaction"]["units"]))
                    time = (datetime.now() + timedelta(hours = 3)).strftime('%m/%d/%Y @ %I:%M %p')
                    if (numUnits == "ALL"):
                        print(CLOSE_POSITION_MESSAGE.format(time=time, instrument=instrument, direction = side, units=units, pl=pl))
                    else:
                        print(CLOSE_PARTIAL_MESSAGE.format(time=time, instrument=instrument, direction = side, units=units, pl=pl))
                except V20Error as err:
                    print("V20Error occurred: {}".format(err))

            # delete entry file
            if os.path.isfile(static.filepath+'entry-'+side+'-'+instrument+'.txt'):
                os.remove(static.filepath+'entry-'+side+'-'+instrument+'.txt')

        except Exception as e:
            print(e)
    return

#######################################
# close trade
#######################################
def close_trade(fn):
    if not is_directory_locked():
        try:
            _,tradeID,side,numUnits = fn.split('-')

            if (numUnits == "0"):
                numUnits = "ALL"

            if (static.live_trading):
                client = oandapyV20.API(static.token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(static.token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})

            if (side == "short"):
                r = trades.TradeClose(static.short_account_id,tradeID,{"units": numUnits})
            else:
                r = trades.TradeClose(static.long_account_id,tradeID,{"units": numUnits})

            try:
                rv = client.request(r)
                #print(rv)

                pl = '{:,.2f}'.format(float(rv["orderFillTransaction"]["pl"]))
                units = abs(int(rv["orderFillTransaction"]["units"]))
                time = (datetime.now() + timedelta(hours = 3)).strftime('%m/%d/%Y @ %I:%M %p')
                instrument = rv["orderFillTransaction"]["instrument"]
                mt4id = rv["orderFillTransaction"]["tradesClosed"][0]["clientTradeID"].replace("@","")
                fxtid = rv["orderFillTransaction"]["tradesClosed"][0]["tradeID"]

                if (numUnits == "ALL"):
                     print(CLOSE_TRADE_MESSAGE.format(time=time, instrument=instrument, direction = side, units=units, mt4id=mt4id, fxtid=fxtid, pl=pl))
                else:
                     print(CLOSE_TRADE_MESSAGE.format(time=time, instrument=instrument, direction = side, units=units, nt4id=mt4id, fxtid=fxtid, pl=pl))
            
            except V20Error as err:
                print("V20Error occurred: {}".format(err))

        except Exception as e:
            print(e)
    return

###################
# open market order
###################
def open_trade(fn):
    if not is_directory_locked():
        try:
            _,pair,side,size,mt4TradeID = fn.split('-')

            size = int(size)

            if (side == "short"):
                size = str(size * -1)

            modOrder = ClientExtensions(
                clientID = "@"+mt4TradeID)

            mktOrder = MarketOrderRequest(
                instrument = str(pair),
                units = str(size),
                tradeClientExtensions = modOrder.data)

            if (static.live_trading):
                client = oandapyV20.API(static.token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(static.token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})
            
            if (side == "short"):
                r = orders.OrderCreate(static.short_account_id,data=mktOrder.data)
            else:
                r = orders.OrderCreate(static.long_account_id,data=mktOrder.data)

            try:
                rv = client.request(r)
                
                if "orderCancelTransaction" in rv:
                    reason = rv["orderCancelTransaction"]["reason"]
                
                    print("NOTICE: "+reason)
                else:
                    units = abs(int(rv["orderFillTransaction"]["units"]))
                    time = (datetime.now() + timedelta(hours = 3)).strftime('%m/%d/%Y @ %I:%M %p')
                    fxtid = int(rv["orderFillTransaction"]["tradeOpened"]["tradeID"])
                    mt4id = rv["orderFillTransaction"]["tradeOpened"]["clientExtensions"]["id"].replace("@","")
                    print(OPEN_TRADE_MESSAGE.format(time=time, instrument=pair, direction=side, units=units, fxtid=fxtid, mt4id=mt4id))
                
            except V20Error as err:
                print("V20Error occurred: {}".format(err))

        except Exception as e:
            print(e)
    return

###########################################
# get Trade ID's
###########################################

def update_trade_data(updateNow = False):

    if not is_directory_locked():
        try:
            # delete all current positions prior to update
            for fn in os.listdir(static.filepath): # loop through files in directory
                if 'FXtTrades.txt' in fn:
                    os.remove(static.filepath+fn)

            if (static.live_trading):
                client = oandapyV20.API(static.token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(static.token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})

            # get long trades
            response = trades.OpenTrades(static.long_account_id)
            rv = client.request(response)
            
            #print(rv)

            currentTrades = []

            for trade in rv["trades"]:

                if trade["state"] == 'OPEN':
                    mt4id = "0"
                    if ("clientExtensions" in trade):
                        if ("id" in trade["clientExtensions"]):
                            mt4id = str(trade["clientExtensions"]["id"])

                    currentTrades.append(str(trade["instrument"].replace("_",""))+"_"+
                                         str("long")+"_"+
                                         str(trade["id"])+"_"+
                                         str(mt4id.replace("@",""))+"_"+
                                         str(trade["openTime"].split('.')[0])+"_"+
                                         str(trade["currentUnits"])+"_"+
                                         str(trade["price"])+"_"+
                                         str(trade["financing"]))

            # get short trades
            response = trades.OpenTrades(static.short_account_id)
            rv = client.request(response)

            for trade in rv["trades"]:

                if trade["state"] == 'OPEN':
                    mt4id = "0"
                    if ("clientExtensions" in trade):
                        if ("id" in trade["clientExtensions"]):
                            mt4id = str(trade["clientExtensions"]["id"])

                    currentTrades.append(str(trade["instrument"].replace("_",""))+"_"+
                                         str("short")+"_"+
                                         str(trade["id"])+"_"+
                                         str(mt4id.replace("@",""))+"_"+
                                         str(trade["openTime"].split('.')[0])+"_"+
                                         str(trade["currentUnits"])+"_"+
                                         str(trade["price"])+"_"+
                                         str(trade["financing"]))

            file = open(static.filepath+"FXtTrades.txt","w")
            for trade in currentTrades:
                file.write(str(trade+"\n"))
            file.close()

        except Exception as e:
            print(e)

######################
# update all positions
######################
def update_positions():

    if not is_directory_locked():
        create_lock_file()
        try:
            # delete all current positions prior to update
            for fn in os.listdir(static.filepath): # loop through files in directory
                if 'position-' in fn:
                    os.remove(static.filepath+fn)

            if (static.live_trading):
                client = oandapyV20.API(static.token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(static.token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})

            # update short positions
            response = positions.OpenPositions(static.short_account_id)
            rv = client.request(response)
            
            #print(rv["positions"])

            for position in rv["positions"]:
                longunits = int(position["long"]["units"])
                shortunits = int(position["short"]["units"]) * -1
                
                if(longunits > 0):
                    side = "buy"
                    units = position["long"]["units"]
                    avgPrice = position["long"]["averagePrice"]
                    total = len(position["long"]["tradeIDs"])
                if(shortunits > 0):
                    side = "sell"
                    units = abs(int(position["short"]["units"]))
                    avgPrice = position["short"]["averagePrice"]
                    total = len(position["short"]["tradeIDs"])
                # create file position-EUR_USD-buy-2500-1.13041
                file = open(static.filepath+"position-"+position.get("instrument")+"-short.txt","w")
                file.write(side+","+
                           str(units)+","+
                           str(avgPrice)+","+
                           str(total))
                file.close()

            # update long positions
            response = positions.OpenPositions(static.long_account_id)
            rv = client.request(response)
            
            #print(rv["positions"])

            for position in rv["positions"]:
                longunits = int(position["long"]["units"])
                shortunits = int(position["short"]["units"]) * -1
                
                if(longunits > 0):
                    side = "buy"
                    units = position["long"]["units"]
                    avgPrice = position["long"]["averagePrice"]
                    total = len(position["long"]["tradeIDs"])
                if(shortunits > 0):
                    side = "sell"
                    units = abs(int(position["short"]["units"]))
                    avgPrice = position["short"]["averagePrice"]
                    total = len(position["short"]["tradeIDs"])
                # create file position-EUR_USD-buy-2500-1.13041
                file = open(static.filepath+"position-"+position.get("instrument")+"-long.txt","w")
                file.write(side+","+
                           str(units)+","+
                           str(avgPrice)+","+
                           str(total))
                file.close()

            print("UPDATE POSITIONS: Success")
        except Exception as e:
            print(e)
        delete_lock_file()
    return

########################
# update account details
########################
def update_account():

    if not is_directory_locked():
        create_lock_file()

        if (static.live_trading):
            client = oandapyV20.API(static.token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
        else:
            client = oandapyV20.API(static.token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})        

        # update short account
        response = accounts.AccountDetails(static.short_account_id)

        try:
            rv = client.request(response)

            file = open(static.filepath+"account-short.txt","w")
            file.write(str(rv["account"]["balance"])+","+
                       str(rv["account"]["openTradeCount"])+","+
                       str(rv["account"]["marginAvailable"])+","+
                       str(rv["account"]["marginUsed"])+","+
                       str(rv["account"]["pl"])
                       )
            file.close()
        except V20Error as err:
            print("V20Error occurred: {}".format(err))

        # update long account
        response = accounts.AccountDetails(static.long_account_id)

        try:
            rv = client.request(response)

            file = open(static.filepath+"account-long.txt","w")
            file.write(str(rv["account"]["balance"])+","+
                       str(rv["account"]["openTradeCount"])+","+
                       str(rv["account"]["marginAvailable"])+","+
                       str(rv["account"]["marginUsed"])+","+
                       str(rv["account"]["pl"])
                       )
            file.close()

            print("UPDATE ACCOUNT:   Success")
        except V20Error as err:
            print("V20Error occurred: {}".format(err))
        
        delete_lock_file()

    return

#############################
# is directory locked by MT4?
#############################
def is_directory_locked():
    locked = False
    try:
        if os.path.isfile(static.filepath+'MT4-Locked'):
            locked = True
    except Exception as e:
        print(e)
    return locked
