*** Settings ***
Documentation       Template robot main suite.

Library    RPA.Robocorp.WorkItems
Library    RPA.Email.ImapSmtp
Library    RPA.Robocorp.Vault

*** Tasks ***
Email watcher
    For Each Input Work Item    Process Email

*** Keywords ***
Process Email
    ${forwarded_email}=    Get Work Item Payload
    Log   ${forwarded_email}[email][from][address]
    Log   ${forwarded_email}[email][subject]

    Authorize Gmail

    # Find the incoming message from gmail
    # TODO: Improve the List messages keyword to use more criteria from the forwarded email
    # to reduce the likelihood of multiple matches.
    @{original_emails}  List Messages   FROM "${forwarded_email}[email][from][address]" SUBJECT "${forwarded_email}[email][subject]"

    # Check how many messages were found and only perform actions if there is one match.
    ${count}=    Get length    ${original_emails}
    IF    $count == ${1}
        Log To Console    One message - processing id ${original_emails}[0][Message-ID]

        # Reply to message
        Reply to message    ${forwarded_email}[email]
        # Flag message with "Robo-Processed"
        Move message to processed    ${original_emails}[0][Message-ID]


    ELSE IF    $count == ${0}
        Log To Console    No messages found
    ELSE
        Log To Console    More than one message found
    END

    Release Input Work Item    DONE

Authorize Gmail
    ${secret}=    Get Secret   Google

    Authorize
    ...   ${secret}[email-demo-email]
    ...   ${secret}[email-demo-app-pwd]
    ...   smtp_server=smtp.gmail.com
    ...   smtp_port=587
    ...   imap_server=imap.gmail.com
    ...   imap_port=993

Move message to processed
    [Arguments]    ${message_id}
    Move Messages By Ids    ${message_id}    Robo-Processed    INBOX

Reply to message
    [Arguments]    ${message}
    Log    ${message}

    ${secret}=    Get Secret   Google

    # TODO: Make some logic for creating a reply here.
    ${body_content}=    Set Variable    The robot has seen your message and decides to ignore it.

    # Construct reply body that repeats users incoming message.
    ${body_reply}=    Set Variable    ${\n}${\n}On ${message}[date] ${message}[from][name] <${message}[from][address]> wrote:${\n}${\n}${message}[body]

    ${body}=    Catenate    ${body_content}    ${body_reply}
    ${subject}=    Catenate    Re:    ${message}[subject]

    Send Message
    ...   sender=${secret}[email-demo-email]
    ...   recipients=${message}[from][address]
    ...   subject=${subject}
    ...   body=${body}


