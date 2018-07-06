import wso2/gsheets4;
import wso2/gmail;
import ballerina/http;
import ballerina/io;
import ballerina/config;
import ballerina/log;



string accessToken = config:getAsString("ACCESS_TOKEN");


string clientId = config:getAsString("CLIENT_ID");


string clientSecret = config:getAsString("CLIENT_SECRET");


string refreshToken = config:getAsString("REFRESH_TOKEN");


string spreadsheetId = config:getAsString("SPREADSHEET_ID");


string sheetName = config:getAsString("SHEET_NAME");


string senderEmail = config:getAsString("SENDER");


string userId = config:getAsString("USER_ID");


endpoint gsheets4:Client spreadsheetClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};

endpoint gmail:Client gmailClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};


function main(string... args){
    string[][] values =getStudentDetailsWhenMarksUpdated();
    int i = 0;
    //Iterate through each student details and send a email with marks received.
    foreach value in values {
        //Skip the first row as it contains header values.
        if (i > 0) {
            string studentName = value[0];
            string studentEmail = value[1];
            string indexNo = value[3];
            string marks = value[5];

            string subject = "Assigment Marks" ;
            sendMail(studentEmail, subject, getEmailTemplate(studentName,indexNo,marks));
        }
        i = i + 1;
    }

}

function getStudentDetailsWhenMarksUpdated() returns (string[][]) {
    //Read all the values from the sheet.
    string[][] values = check spreadsheetClient->getSheetValues(spreadsheetId, sheetName, "", "");
    log:printInfo("Retrieved customer details from spreadsheet id:" + spreadsheetId + " ;sheet name: "
            + sheetName);
    return values;
}

function getEmailTemplate(string studentName, string indexNo,string mark) returns (string) {
    string emailTemplate = "<h5> Hi " + studentName + " </h5>";
    emailTemplate = emailTemplate + "<h3> Your Assigment is marked! </h3>";
    emailTemplate = emailTemplate + "<h4> Your Index Number " + indexNo +
        "</h4> ";
    emailTemplate = emailTemplate + "<h3> Marks You received " + mark + " </h3> ";
    emailTemplate = emailTemplate + "<p> Reply to this email if you want to clarify any problem regarding your marks </p> ";
    return emailTemplate;
}

function sendMail(string studentEmail, string subject, string messageBody) {
    //Create html message
    gmail:MessageRequest messageRequest;
    messageRequest.recipient = studentEmail;
    messageRequest.sender = senderEmail;
    messageRequest.subject = subject;
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;

    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint messageRequest);
    string messageId;
    string threadId;
    match sendMessageResponse {
        (string, string) sendStatus => {
            (messageId, threadId) = sendStatus;
            log:printInfo("Sent email to " + studentEmail + " with message Id: " + messageId + " and thread Id:"
                    + threadId);
        }
        gmail:GmailError e => log:printInfo(e.message);
    }
}


