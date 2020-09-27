#TODO: make basic server that can handle post requests from app
from flask import request, url_for
from flask_api import FlaskAPI, status, exceptions
from send_email import send_email
from web_injection import buy_items

app = FlaskAPI(__name__)

items = {} #keeping track of the items to order

#Executing the ordering and emailing tasks
@app.route("/", methods = ['GET', 'POST'])
def execute_order():
    if request.method == 'POST':
        new_items = str(request.data.get('item_list', ''))
        new_quants = str(request.data.get('quantity_list', ''))

        for item, quant in zip(new_items.split('~'), new_quants.split('~')):
            items[item] = int(quant)

        buy_items(items)

        o_str = '\n'.join([k + ' ' + str(v) for k, v in items.items()])

        send_email(user = 'Clare', order_str = o_str) #send out the email with the correct username and link

        return items

    return items

#EXAMPLE JSON: {"item_list" : "milk~cheese","quantity_list" : "1~3"}

if __name__ == '__main__':
    app.run(debug = True)


