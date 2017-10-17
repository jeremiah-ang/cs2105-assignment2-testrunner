# cs2105-assignment2-testrunner

## Download
`git clone https://github.com/jeremiah-ang/cs2105-assignment2-testrunner`

or Simply download the the `tests/` folder and `startChat.sh` file :)

## Create Test Cases
#### test cases must be of the format
`test#/test#.in`

`test#/test#.out`

- where # is the test number 

- test#/result# will be generated automatically

## Running test cases
`./startChat <TEST NO.> [LAST_FILE_TRANSMITTED]`

<TEST NO.> --> The test # to be run on
[LAST_FILE_TRANSMITTED] --> The last file to be transmitted to be check for content, can be empty


Run the test with input1.in and output should be Alice.java:

`./startChat 1 Alice.java` 

Run the test with input3.in and does not expect any file transfer:

`./startChat 3` 

**Error** - expect first argument to be a Test number that exist (Uncaught):

`./startChat Alice.java`
