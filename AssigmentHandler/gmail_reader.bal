import wso2/gsheets4;
import wso2/gmail;
import ballerina/http;
import ballerina/io;
import ballerina/config;
import ballerina/log;
import ballerina/mime;



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
    string user_id="thilinidi@wso2.com";


    gmail:MessageListPage msgList;
    gmail:MsgSearchFilter filter;
    filter.labelIds = ["Label_1"];


    var defntn  = gmailClient->listMessages(user_id,filter = filter);
    match defntn{
        gmail:MessageListPage lst => msgList = lst;
        gmail:GmailError err => io:println(err);
    }


    string[] arrayOfMsgIds = [];
    //<string>5----->converting data types,
    int i = 0;
    //int k=<int>msgList.resultSizeEstimate;
    while (i < 10) {
        string message_Id = <string>msgList["messages"][i]["messageId"];
        arrayOfMsgIds[i] =message_Id;
        io:println(message_Id);
        i++;
    }


    int round=2;
    foreach msg_id in arrayOfMsgIds {
        boolean result = checkTheMailIsAnAssigmentSubmission(msg_id);
        if (result){
            string[] values = readDataFromEmails(msg_id);
            //update the google sheet with submission details
            addDetailsToGSheet(values, round);
            string subject = "Assigment Submission Confirmation" ;
            sendMail(values[1], subject, getEmailTemplate(values[0]));
            round++;
        }
    }


}
function checkTheMailIsAnAssigmentSubmission(string msg_id ) returns (boolean){
    string subject;
    var response=gmailClient->readMessage(userId,msg_id);
    gmail:Message msg;
    match response {
        gmail:Message m => msg = m;
        gmail:GmailError err=> io:println(err);
    }
    subject=msg["headerSubject"];
    if (subject== "Assigment Submission") {
        io:println("found a assigment submission email!!");
        return  true;
    }else{
        return false;
    }

}

function readDataFromEmails(string msg_id ) returns (string[])  {
    string indexNo;
    string index_no_of_student;
    string submissionLink;
    string[] hfrom;
    string studentName;
    string email;
    string date;



    var response=gmailClient->readMessage(userId,msg_id);
    gmail:Message msg;
    match response {
        gmail:Message m => msg = m;
        gmail:GmailError err=> io:println(err);
    }


    string snipp1;
    snipp1 = msg["snippet"];
    indexNo=snipp1.substring(0,7);
    string submissionLink1=snipp1.substring(7,snipp1.length());
    submissionLink=submissionLink1.split("--")[0];
    io:println("Drive location Link"+submissionLink);

    //read the body of the email to get student data.Index no is the only text on the body
    //string index_no_of_student;
    //gmail:MessageBodyPart[] msg_body=msg["msgAttachments"];

   // var file_id=msg_body[0].body;
   // io:println("file_id"+file_id);

    //var fileName=msg_body[0].fileName;
    //io:println("file_name"+fileName);


    //gmail:MessageBodyPart msg_body=msg["plainTextBodyPart"];
    //string file_id=msg["raw"];
    //string encoded_email_body1=msg_body.body;
    //string[] encoded_email_body=encoded_email_body1.split("/n");
    //var encoded_email_content=encoded_email_body[0];
    //var encoded_drive_link=encoded_email_body[0];
    //io:println("file_id"+file_id);


    //string email_body;
    //string email_body_decoded=mime:base64DecodeString(file_id);
    //match email_body_decoded{
        //string lst => email_body = lst;
       // mime:error err => io:println(err);
    //}
    //io:println("all text in mail"+email_body);


    string hfrom1;
    hfrom1=msg["headerFrom"];
    hfrom=hfrom1.split("<");
    studentName=hfrom[0];
    email=hfrom[1].substring(0,hfrom[1].length()-1);
    date=msg["internalDate"];

    string[] values=[studentName,email,date,indexNo,submissionLink];
    return values;

}

function addDetailsToGSheet(string[] valuestoAdd,int round) {

    string topLeftCell="A"+<string>round;
    string bottomRightCell="E"+<string>round;
    //string topLeftCell="A0";
    //string bottomRightCell="C0";
    string[][] values=[[valuestoAdd[0],valuestoAdd[1],valuestoAdd[2],valuestoAdd[3],valuestoAdd[4]]];

    var spreadsheetRes = spreadsheetClient->setSheetValues(spreadsheetId, sheetName, topLeftCell, bottomRightCell, values);
    match spreadsheetRes {
        boolean isUpdated => io:println(isUpdated);
    gsheets4:SpreadsheetError e => io:println(e);
    }
}
function getEmailTemplate(string studentName) returns (string) {
    string emailTemplate = "<h5> Hi " + studentName + " </h5>";
    emailTemplate = emailTemplate + "<h4> Your Assigment is submitted successfully! </h4>";
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







