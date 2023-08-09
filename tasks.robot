*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates Zip archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Download and store the receipt and image    ${order}[Order number]
        Order another robot
    END
    Create a ZIP file of receipt PDF files
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Read orders file as a table
    ${orders}=    Read table from CSV    orders.csv

Get orders
    Download the orders file
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Log    ${order}
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    id-body-${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    Preview
    Mute Run On Failure    Submit the order
    Wait Until Keyword Succeeds    10x    0.5s    Submit the order

Submit the order
    Click Button    order
    Wait Until Page Contains Element    receipt    timeout=0.3s

Store the order receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt${order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipt${order_number}.pdf

Take a screenshot of the robot image
    [Arguments]    ${order_number}
    ${robot_img}=    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot${order_number}.png
    RETURN    ${robot_img}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

Download and store the receipt and image
    [Arguments]    ${order_number}
    ${pdf}=    Store the order receipt as a PDF file    ${order_number}
    ${screenshot}=    Take a screenshot of the robot image    ${order_number}
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}

Order another robot
    Click Button    order-another

Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}receipts.zip    include=*.pdf
