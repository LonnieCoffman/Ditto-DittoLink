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

CLOSE_TRADE_MESSAGE = '''{system}: TRADE CLOSED: {dashes}
                  Time:   {time} EST
                  Pair:   {instrument}
                  Units:  {units} ({direction})
                  FXtID:  {fxtid}
                  MT4ID:  {mt4id}
                  P/L:   ${pl}
                  ==============================='''
CLOSE_POSITION_MESSAGE = '''{system}: POSITION CLOSED: {dashes}
                  Time:   {time} EST
                  Pair:   {instrument}
                  Units:  {units} ({direction})
                  P/L:   ${pl}
                  ==============================='''
CLOSE_PARTIAL_MESSAGE = '''{system}: PARTIAL CLOSE: {dashes}
                  Time:   {time} EST
                  Pair:   {instrument}
                  Units:  {units} ({direction})
                  P/L:   ${pl}
                  ==============================='''
OPEN_TRADE_MESSAGE = '''{system}: TRADE OPENED: {dashes}
                  Time:   {time} EST
                  Pair:   {instrument}
                  Units:  {units} ({direction})
                  FXtID:  {fxtid}
                  MT4ID:  {mt4id}
                  ==============================='''

#######################################################
# create a lock file to prevent mt4 from accessing data
#######################################################
def create_lock_file(dir):
    try:
        file = open(dir+"\\\\bridge_lock","w")
        file.close()
    except Exception as e:
        print(e)
    return

############################
# delete the above lock file
############################
def delete_lock_file(dir):
    try:
        if os.path.isfile(dir+"\\\\bridge_lock"):
            os.remove(dir+"\\\\bridge_lock")
    except Exception as e:
        print(e)
    return

###############################################################################
# create an alive check file - an EA can use this to check if script is running
###############################################################################
def alive_check(dir):
    if not is_directory_locked(dir):
        try:
            if not os.path.isfile(dir+"\\\\alive_check"):
                create_lock_file(dir)
                file = open(dir+"\\\\alive_check","w")
                file.close()
                delete_lock_file(dir)
        except Exception as e:
            print(e)
    return

#######################################
# close all positions for an instrument
#######################################
def close_position(token, filepath, filename, first_account_id, second_account_id, live_trading, system):
    if not is_directory_locked(filepath):
        try:
            _,instrument,side,numUnits = filename.split('-')

            if (numUnits == "0"):
                numUnits = "ALL"

            if (live_trading):
                client = oandapyV20.API(token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})

            if (side == "long" or side == "both"):
                #close long positions
                if (second_account_id == ""):
                    r = positions.PositionClose(first_account_id, instrument, {"longUnits": numUnits})
                else:
                    r = positions.PositionClose(second_account_id, instrument, {"longUnits": numUnits})
                try:
                    client.request(r)
                    pl = '{:,.2f}'.format(float(r.response["longOrderFillTransaction"]["pl"]))
                    units = abs(int(r.response["longOrderFillTransaction"]["units"]))
                    time = (datetime.now() + timedelta(hours = 3)).strftime('%m/%d/%Y @ %I:%M %p')
                    if (numUnits == "ALL"):
                        dashes = (50-19-(len(system)))*"="
                        print(CLOSE_POSITION_MESSAGE.format(dashes=dashes, system=system, time=time, instrument=instrument, direction = side, units=units, pl=pl))
                    else:
                        dashes = (50-17-(len(system)))*"="
                        print(CLOSE_PARTIAL_MESSAGE.format(dashes=dashes, system=system, time=time, instrument=instrument, direction = side, units=units, pl=pl))
                except V20Error as err:
                    print("V20Error occurred: {}".format(err))

            if (side == "short" or side == "both"):
                #close short positions
                r = positions.PositionClose(first_account_id, instrument, {"shortUnits": numUnits})
                try:
                    client.request(r)
                    pl = '{:,.2f}'.format(float(r.response["shortOrderFillTransaction"]["pl"]))
                    units = abs(int(r.response["shortOrderFillTransaction"]["units"]))
                    time = (datetime.now() + timedelta(hours = 3)).strftime('%m/%d/%Y @ %I:%M %p')
                    if (numUnits == "ALL"):
                        dashes = (50-19-(len(system)))*"="
                        print(CLOSE_POSITION_MESSAGE.format(dashes=dashes, system=system, time=time, instrument=instrument, direction = side, units=units, pl=pl))
                    else:
                        dashes = (50-17-(len(system)))*"="
                        print(CLOSE_PARTIAL_MESSAGE.format(dashes=dashes, system=system, time=time, instrument=instrument, direction = side, units=units, pl=pl))
                except V20Error as err:
                    print("V20Error occurred: {}".format(err))

        except Exception as e:
            print(e)
    return

#######################################
# close trade
#######################################
def close_trade(token, filepath, filename, first_account_id, second_account_id, live_trading, system):
    if not is_directory_locked(filepath):
        try:
            _,tradeID,side,numUnits = filename.split('-')

            if (numUnits == "0"):
                numUnits = "ALL"

            if (live_trading):
                client = oandapyV20.API(token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})

            if (side == "short"):
                r = trades.TradeClose(first_account_id,tradeID,{"units": numUnits})
            else:
                if (second_account_id == ""):
                    r = trades.TradeClose(first_account_id,tradeID,{"units": numUnits})
                else:
                    r = trades.TradeClose(second_account_id,tradeID,{"units": numUnits})

            try:
                rv = client.request(r)
                # print(rv)

                if "orderCancelTransaction" in rv:
                    reason = rv["orderCancelTransaction"]["reason"]
                
                    print("NOTICE: "+reason)
                    print("DETAILS: "+rv["orderCreateTransaction"]["instrument"]+"|"+side+"|"+rv["orderCreateTransaction"]["units"]+"| #"+rv["orderCreateTransaction"]["tradeClose"]["tradeID"])
                else:

                    pl = '{:,.2f}'.format(float(rv["orderFillTransaction"]["pl"]))
                    units = abs(int(rv["orderFillTransaction"]["units"]))
                    time = (datetime.now() + timedelta(hours = 3)).strftime('%m/%d/%Y @ %I:%M %p')
                    instrument = rv["orderFillTransaction"]["instrument"]
                    mt4id = rv["orderFillTransaction"]["tradesClosed"][0]["clientTradeID"].replace("@","")
                    fxtid = rv["orderFillTransaction"]["tradesClosed"][0]["tradeID"]

                    if (numUnits == "ALL"):
                        dashes = (50-16-(len(system)))*"="
                        print(CLOSE_TRADE_MESSAGE.format(dashes=dashes, system=system, time=time, instrument=instrument, direction = side, units=units, mt4id=mt4id, fxtid=fxtid, pl=pl))
                    else:
                        dashes = (50-16-(len(system)))*"="
                        print(CLOSE_TRADE_MESSAGE.format(dashes=dashes, system=system, time=time, instrument=instrument, direction = side, units=units, nt4id=mt4id, fxtid=fxtid, pl=pl))
                
            except V20Error as err:
                print("V20Error occurred: {}".format(err))

        except Exception as e:
            print(e)
    return

###################
# open market order
###################
def open_trade(token, filepath, filename, first_account_id, second_account_id, live_trading, system):
    if not is_directory_locked(filepath):
        try:
            _,pair,side,size,mt4TradeID = filename.split('-')

            size = int(size)

            if (side == "short"):
                size = str(size * -1)

            modOrder = ClientExtensions(
                clientID = "@"+mt4TradeID)

            mktOrder = MarketOrderRequest(
                instrument = str(pair),
                units = str(size),
                tradeClientExtensions = modOrder.data)

            if (live_trading):
                client = oandapyV20.API(token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})
            
            if (side == "short"):
                r = orders.OrderCreate(first_account_id,data=mktOrder.data)
            else:
                if (second_account_id == ""):
                    r = orders.OrderCreate(first_account_id,data=mktOrder.data)
                else:
                    r = orders.OrderCreate(second_account_id,data=mktOrder.data)

            try:
                rv = client.request(r)
                
                if "orderCancelTransaction" in rv:
                    reason = rv["orderCancelTransaction"]["reason"]
                
                    print("NOTICE: "+reason)
                    print("DETAILS: "+pair+"|"+side+"|"+str(size)+"|"+mt4TradeID)
                else:
                    units = abs(int(rv["orderFillTransaction"]["units"]))
                    time = (datetime.now() + timedelta(hours = 3)).strftime('%m/%d/%Y @ %I:%M %p')
                    fxtid = int(rv["orderFillTransaction"]["tradeOpened"]["tradeID"])
                    mt4id = rv["orderFillTransaction"]["tradeOpened"]["clientExtensions"]["id"].replace("@","")
                    dashes = (50-16-(len(system)))*"="
                    print(OPEN_TRADE_MESSAGE.format(dashes=dashes, system=system, time=time, instrument=pair, direction=side, units=units, fxtid=fxtid, mt4id=mt4id))
                
            except V20Error as err:
                print("V20Error occurred: {}".format(err))

        except Exception as e:
            print(e)
    return

###########################################
# get Trade ID's
###########################################

def update_trade_data(token, filepath, first_account_id, second_account_id, live_trading, updateNow = False):

    if not is_directory_locked(filepath):
        try:
            # delete all current positions prior to update
            for fn in os.listdir(filepath+"\\\\"): # loop through files in directory
                if 'FXtTrades.txt' in fn:
                    os.remove(filepath+"\\\\"+fn)

            if (live_trading):
                client = oandapyV20.API(token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})

            currentTrades = []
            
            if (second_account_id == ""):
                # get combined
                response = trades.OpenTrades(first_account_id)
                rv = client.request(response)

                #print(rv)

                for trade in rv["trades"]:

                    if trade["state"] == 'OPEN':
                        mt4id = "0"
                        if ("clientExtensions" in trade):
                            if ("id" in trade["clientExtensions"]):
                                mt4id = str(trade["clientExtensions"]["id"])

                        if (int(trade["currentUnits"]) > 0):
                            side = "long"
                        else:
                            side = "short"

                        currentTrades.append(str(trade["instrument"].replace("_",""))+"_"+
                                            str(side)+"_"+
                                            str(trade["id"])+"_"+
                                            str(mt4id.replace("@",""))+"_"+
                                            str(trade["openTime"].split('.')[0])+"_"+
                                            str(trade["currentUnits"])+"_"+
                                            str(trade["price"])+"_"+
                                            str(trade["financing"]))
            else:
                # get long trades
                response = trades.OpenTrades(second_account_id)
                rv = client.request(response)
                
                #print(rv)

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
                response = trades.OpenTrades(first_account_id)
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

            file = open(filepath+"\\\\FXtTrades.txt","w")
            for trade in currentTrades:
                file.write(str(trade+"\n"))
            file.close()

        except Exception as e:
            print(e)

######################
# update all positions
######################
def update_positions(token, filepath, first_account_id, second_account_id, live_trading, system):

    if not is_directory_locked(filepath):
        create_lock_file(filepath)
        try:
            # delete all current positions prior to update
            for fn in os.listdir(filepath+"\\\\"): # loop through files in directory
                if 'position-' in fn:
                    os.remove(filepath+"\\\\"+fn)

            if (live_trading):
                client = oandapyV20.API(token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
            else:
                client = oandapyV20.API(token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})

            # update short positions
            response = positions.OpenPositions(first_account_id)
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
                if side == "sell":
                    direction = "short"
                else:
                    direction = "long"
                file = open(filepath+"\\\\position-"+position.get("instrument")+"-"+direction+".txt","w")
                file.write(side+","+
                           str(units)+","+
                           str(avgPrice)+","+
                           str(total))
                file.close()

            # update long positions
            if (second_account_id != ""):
                response = positions.OpenPositions(second_account_id)
           
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
                    file = open(filepath+"\\\\position-"+position.get("instrument")+"-long.txt","w")
                    file.write(side+","+
                            str(units)+","+
                            str(avgPrice)+","+
                            str(total))
                    file.close()

            print(system+": UPDATE POSITIONS: Success")
        except Exception as e:
            print(e)
        delete_lock_file(filepath)
    return

########################
# update account details
########################
def update_account(token, filepath, first_account_id, second_account_id, live_trading, system):

    if not is_directory_locked(filepath):
        create_lock_file(filepath)

        if (live_trading):
            client = oandapyV20.API(token, environment='live',headers={"Accept-Datetime-Format":"Unix"})
        else:
            client = oandapyV20.API(token, environment='practice',headers={"Accept-Datetime-Format":"Unix"})        

        # combined account
        if (second_account_id == ""):
            # remove individual account details
            if os.path.exists(filepath+"\\\\account-short.txt"):
                os.remove(filepath+"\\\\account-short.txt")
            if os.path.exists(filepath+"\\\\account-long.txt"):
                os.remove(filepath+"\\\\account-long.txt")

            # update combined account
            response = accounts.AccountDetails(first_account_id)

            try:
                rv = client.request(response)

                file = open(filepath+"\\\\account-combined.txt","w")
                file.write(str(rv["account"]["balance"])+","+
                        str(rv["account"]["openTradeCount"])+","+
                        str(rv["account"]["marginAvailable"])+","+
                        str(rv["account"]["marginUsed"])+","+
                        str(rv["account"]["pl"])
                        )
                file.close()

                print(system+": UPDATE ACCOUNT:   Success")
            except V20Error as err:
                # if there was an error with account record message in error.txt. this will stop all activity in this account.
                print(err)
                file = open(filepath+"\\\\error.txt","w")
                file.write(str(err))
                file.close()
        else:
            # remove combined account details
            if os.path.exists(filepath+"\\\\account-combined.txt"):
                os.remove(filepath+"\\\\account-combined.txt")
            
            # update short account
            response = accounts.AccountDetails(first_account_id)

            try:
                rv = client.request(response)

                file = open(filepath+"\\\\account-short.txt","w")
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
            response = accounts.AccountDetails(second_account_id)

            try:
                rv = client.request(response)

                file = open(filepath+"\\\\account-long.txt","w")
                file.write(str(rv["account"]["balance"])+","+
                        str(rv["account"]["openTradeCount"])+","+
                        str(rv["account"]["marginAvailable"])+","+
                        str(rv["account"]["marginUsed"])+","+
                        str(rv["account"]["pl"])
                        )
                file.close()

                print(system+": UPDATE ACCOUNT:   Success")
            except V20Error as err:
                print("V20Error occurred: {}".format(err))
        
        delete_lock_file(filepath)

    return

#############################
# is directory locked by MT4?
#############################
def is_directory_locked(dir):
    locked = False
    try:
        if os.path.isfile(dir+'\\\\MT4-Locked'):
            locked = True
    except Exception as e:
        print(e)
    return locked
