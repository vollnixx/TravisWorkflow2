#!/bin/bash

# Produce data
#libs/composer/vendor/phpunit/phpunit/phpunit --bootstrap ./libs/composer/vendor/autoload.php --configuration ./Services/PHPUnit/config/PhpUnitConfig.xml --exclude-group needsInstalledILIAS --verbose $@ | tee /tmp/phpunit_results

cp phpunit_results /tmp/phpunit_results

# Init paths
RESULT=`tail -n1 < /tmp/phpunit_results`
PHPUNIT_PATH="/tmp/phpunit_latest.csv"
PHPUNIT_PATH_TMP="/tmp/phpunit_changed.csv"
DICTO_PATH="/tmp/dicto_latest.csv"

# Collect data
SPLIT_RESULT=(`echo $RESULT | tr ':' ' '`)
if [ -e "include/inc.ilias_version.php" ]
	then
		PHP_VERSION=`php -r "echo PHP_MAJOR_VERSION . '_' . PHP_MINOR_VERSION;"`
		ILIAS_VERSION=`php -r "require_once 'include/inc.ilias_version.php'; echo ILIAS_VERSION_NUMERIC;"`
		ILIAS_VERSION=`echo "$ILIAS_VERSION" | tr . _`
fi

JOB_ID=`echo $TRAVIS_JOB_NUMBER`
JOB_URL=`echo $TRAVIS_JOB_WEB_URL`
FAILURE=false
declare -A RESULTS=([Tests]=0 [Assertions]=0 [Errors]=0 [Warnings]=0 [Skipped]=0 [Incomplete]=0 [Risky]=0);
for TYPE in "${!RESULTS[@]}"; 
	do 
		for PHP_UNIT_RESULT in "${!SPLIT_RESULT[@]}"; 
			do 
				if [ "$TYPE" == "${SPLIT_RESULT[$PHP_UNIT_RESULT]}" ]
					then
						CLEANED=(`echo ${SPLIT_RESULT[$PHP_UNIT_RESULT + 1]} | tr ',.' ' '`)
						RESULTS[$TYPE]=$CLEANED;
				fi
			done 
	done

if [ ${RESULTS[Errors]} > 0 ]
	then
		FAILURE=true
fi
# Clean lines
grep -v "$ILIAS_VERSION.*php_$PHP_VERSION" $PHPUNIT_PATH > $PHPUNIT_PATH_TMP 
# Write line
echo "NEW_LINE: $JOB_URL,$JOB_ID,$ILIAS_VERSION,php_$PHP_VERSION,PHP $PHP_VERSION,${RESULTS[Warnings]},${RESULTS[Skipped]},${RESULTS[Incomplete]},${RESULTS[Tests]},${RESULTS[Errors]},${RESULTS[Risky]},$FAILURE";

echo "$JOB_URL,$JOB_ID,$ILIAS_VERSION,php_$PHP_VERSION,PHP $PHP_VERSION,${RESULTS[Warnings]},${RESULTS[Skipped]},${RESULTS[Incomplete]},${RESULTS[Tests]},${RESULTS[Errors]},${RESULTS[Risky]},$FAILURE" >> "$PHPUNIT_PATH_TMP";
if [ -e "$PHPUNIT_PATH_TMP" ]
	then
		mv "$PHPUNIT_PATH_TMP" "$PHPUNIT_PATH"
		#rm /tmp/phpunit_results
fi
# Result handling
TMP_DIRECTORY="/tmp/TravisResults"
if [ -d "$TMP_DIRECTORY" ]; then
	echo "Starting to remove old tmp dir..."
	rm -rf "$TMP_DIRECTORY"
	echo "removing old tmp dir done."
fi
cd /tmp && git clone https://github.com/vollnixx/TravisResults
cd "$TMP_DIRECTORY" && ./run.sh