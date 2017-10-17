function header {
	echo "-> "$1
}

function block_header {
	echo "===================================================="
	echo "===================================================="
	echo "         "$1
	echo "===================================================="
	echo "===================================================="

}

function kill_all {
	bobPID=$1
	urnPID=$2

	if [ -n "$3" ]; then
		header "Killing Alice ($3)"
		kill -9 $3
		header "Alice Died"
	fi

	header "Killing Bob ($bobPID)"
	kill -9 $bobPID
	header "Bob Died"
	header "Killing Unreliable Network ($urnPID)"
	kill -9 $urnPID
	header "Unreliable Network Died"
}

function wait_and_kill {

	alicePID=$1
	bobPID=$2
	urnPID=$3

	# if ctrl-c, manually kill child processes
	trap 'kill_all $bobPID $urnPID $alicePID ' INT

	# wait for alice to end
	wait $alicePID
	header "Alice Ended"

	# Once alice ends, close bob and unrelinet by killing them 
	kill_all $bobPID $urnPID

	# untrap
	trap - INT
}

function compute_result {
	# Compute differece between test#.out and bob.out
	# The messages should be the same
	result=$(diff $TESTOUT $BOBOUT)

	# Compute difference between output and expected output
	if [ -n "$5" ]; then
		output_file="output"
		result=$(diff $LAST_TRANSMITTED_FILENAME $output_file)
	fi

	# print result of this test case
	echo "" >> $RESULT
	if [ "$result" != "" ]; then
		echo "$result" >> $RESULT
	else 
		echo "        Test Case PASSED!" >> $RESULT
	fi

	# just to print many empty lines
	echo "" >> $RESULT
	echo "" >> $RESULT
	echo "" >> $RESULT
	echo "" >> $RESULT
	echo "" >> $RESULT
	echo "" >> $RESULT
	echo "" >> $RESULT
	echo "" >> $RESULT
}

function run {

	# Usage: run <P_DATA_CORRUPT> <P_DATA_LOSS> <P_ACK_CORRUPT> <P_ACK_LOSS> [LAST_TRANSMITTED_FILENAME]

	# Runs Alice, Bob and UnreliNET
	# Takes input from test#.in and put into Alice
	# Output of Bob in output/bob.out is checked with test#.out

	# Host and Port settings here:
	HOST=localhost
	UNRELINETPORT=9000
	RCVPORT=9001	

	# Start up Bob & 
	# output of Bob is stored in output/bob.out &
	# stores it's process ID to be killed after alice finishes 
	java Bob $RCVPORT > $BOBOUT &
	bobPID=$!

	# Start up UnreliNET & 
	# output of UnreliNET is stored in output/urn.out &
	# stores it's process ID to be killed after alice finishes
	java UnreliNET $1 $2 $3 $4 $UNRELINETPORT $RCVPORT > $URNOUT &
	urnPID=$!

	# Start up Alice with input from test#/test#.in & 
	# output of Alice is stored in output/alice.out &
	# stores it's process ID to be killed after alice finishes
	java Alice $HOST $UNRELINETPORT < $TESTIN > $ALICEOUT &
	alicePID=$!

	# Some logging message
	header "Channels Running"	
	header "PIDS >> Bob: $bobPID URN: $urnPID Alice: $alicePID"

	# Wait and close the processes
	wait_and_kill $alicePID $bobPID $urnPID

	# compute and print result to tests/test#/result#
	compute_result
}

function run_tests {
	header "=================================================="

	header "Testing Completely Reliable Channel"
	block_header "Testing Completely Reliable Channel" >> $RESULT

	run 0 0 0 0 $LAST_TRANSMITTED_FILENAME

	header "=================================================="

	header "Testing Slightly unReliable Channel"
	block_header "Testing Slightly Reliable Channel" >> $RESULT

	run 0.2 0.2 0.2 0.2 $LAST_TRANSMITTED_FILENAME

	header "=================================================="

	header "Testing unReliable Channel"
	block_header "Testing Reliable Channel" >> $RESULT

	run 0.4 0.5 0.3 0.5 $LAST_TRANSMITTED_FILENAME
}

function extractJavaFiles {
	# Find all the *.java files 
	# return a space-delimited String of .java file names
	javafiles=$(find . -type f -name "*.java" -maxdepth 1)
	files=""
	for file in $javafiles; do
		filename=$(basename $file)
		filename="${filename%.*}"
		files+=" $filename"
	done
	echo $files
}

function compile_java_files {
	files=$(extractJavaFiles)
	pids=""
	
	header "Javac Programs"
	mkdir tmp
	for file in $files; do
		javac $file.java 2>tmp/$file.log &
		pids+=" $!" 
	done

	filesArr=($files)
	i=0
	shouldTerminate=0
	for p in $pids; do
		if wait $p; then
			header "$i: javac ${filesArr[$i]}.java Success!"
		else 
			header "$i: javac ${filesArr[$i]}.java Failed"
			cat tmp/${filesArr[i]}.log
			echo ""
			shouldTerminate=1
		fi
		((i++))
	done
	rm -rf tmp

	if [ $shouldTerminate -eq 1 ]; then
		echo "Compilation Error!"
		exit 0
	fi
}

# PROGRAM STARTS HERE

if [ -z "$1" ]; then
	echo "Usage: ./startChat.sh <TEST NO.> [LAST_TRANSMITTED_FILENAME]"
	exit 0
fi


# DEFINE FILES 
nTEST=$1
LAST_TRANSMITTED_FILENAME=$2
TESTPREFIX="test"
TESTS="./tests/"
TESTS_DIR=$TESTS"test"$nTEST"/"
OUTPUT_DIR=$TESTS"output/"
TESTIN=$TESTS_DIR$TESTPREFIX$nTEST".in"
TESTOUT=$TESTS_DIR$TESTPREFIX$nTEST".out"
ALICEOUT=$OUTPUT_DIR"alice.out"
BOBOUT=$OUTPUT_DIR"bob.out"
URNOUT=$OUTPUT_DIR"urn.out"
RESULT=$TESTS_DIR"result"$nTEST
> $RESULT # Empty result file

header "Start Chat!"

compile_java_files
run_tests

echo "=================================================="
echo "=================================================="
