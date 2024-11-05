import os
import smtplib
import sys
from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


def send_email(sender, recipients, subject, message, attachment_path_list=None):
    # SMTP server configuration
    SMTP_SERVER = "smtp.messaging.svc"
    SMTP_PORT = 1025
    SMTP_USERNAME = ""
    SMTP_PASSWORD = ""

    # Create MIMEText message
    msg = MIMEMultipart()
    msg['From'] = sender
    msg['To'] = recipients
    msg['Subject'] = subject
    msg.attach(MIMEText(message, 'html'))

    # Attach file if attachment_path is provided
    if attachment_path_list is not None:
        for each_file_path in attachment_path_list:
            try:
                with open(each_file_path, 'rb') as f:
                    part = MIMEBase('application', 'octet-stream')
                    part.set_payload(f.read())
                    encoders.encode_base64(part)
                    part.add_header(
                        'Content-Disposition', f"attachment; filename={os.path.basename(each_file_path)}")
                    msg.attach(part)
            except:
                print("could not attache file")
    try:
        print('inside try')
        # Setup the SMTP server and send the email
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:

            #            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.sendmail(sender, recipients, msg.as_string())
        print("Email sent successfully.")
    except Exception as e:
        print(f"Error sending email: {e}")


if __name__ == "__main__":
    if len(sys.argv) >= 6:
        attachment_path_list = sys.argv[5:len(sys.argv)]
    else:
        attachment_path_list = None
    sender = sys.argv[1]
    recipients = sys.argv[2]
    subject = sys.argv[3]
    message = sys.argv[4]
    send_email(sender, recipients, subject, message, attachment_path_list)


# Example usage:
# send_email("bia-ds-cwb-prd-no-reply@apps.lrl.lilly.com", ["mishra_prabhat1@lilly.com"], "Test Subject", "Test Message")
