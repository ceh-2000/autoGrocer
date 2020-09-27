#Send an email to the user with the checkout URL and maybe some additional info!
import smtplib
import ssl
import json

def send_email(user = 'Mrs. Person', link = 'https://giantfood.com/', order_str = None):
    with open('email_creds.txt', 'r') as file:
        email_creds = file.read().split('\n')
        sender_email = email_creds[0]
        password = email_creds[1]

    port = 465
    smtp_server = 'smtp.gmail.com'
    receiver_email = 'ceheinbaugh@email.wm.edu'

    with open('message.txt', 'r') as file:
        message = file.read() % (user, link)

    if order_str is not None:
        message += '\nYour order:\n' + order_str

    # print(message)

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL(smtp_server, port, context = context) as server:
        server.login(sender_email, password)
        server.sendmail(sender_email, receiver_email, message)

if __name__ == '__main__':
    send_email(order_str = 'milk 3\neggs 4')
