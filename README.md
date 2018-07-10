Ballerina Student Assigment Handling

**This project involves a integration of 2 SaaS services(Gmail and Google Spreadsheets) using Ballerina**

The solution applies to educational institutions which conduct courses. Suppose a co-coordinator of a course wants to ask his/her students to submit completed assignments attached to a email. G-mail and Google Sheets is integrated to provide a reliable solution to the module coordinator’s requirement.

**Functionalities Provided**

1.Each student will send a email to the module coordinator with the assignment attached.

2.Ballerina integrator will filter those emails , add student assignment details to a Google sheet,and send a confirmation email to the student.

3.Once the coordinator check assignments and updates the sheet with marks,ballerina integrator will send a customized automated email to each student with his/her marks received.

**Block Diagrams for the solution**


![withoutgoogledrive](https://user-images.githubusercontent.com/25500034/42499056-7350b356-844b-11e8-8b9d-8ba0f52cd443.png)
![blockdiagram2](https://user-images.githubusercontent.com/25500034/42499069-78cb0cbe-844b-11e8-8698-12d99cbecf67.png)

**Implementation**

WSO2 Ballerina Gmail Package and GSheets package provides required methods to integrate Gmail and Spreadsheet.
