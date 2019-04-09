#!/bin/bash
PRE="\t*** "

# Init paths
PHPUNIT_PATH="/tmp/phpunit_latest.csv"
PHPUNIT_PATH_TMP="/tmp/phpunit_changed.csv"
PHPUNIT_RESULTS_PATH="/tmp/phpunit_results"
DICTO_PATH="/tmp/dicto_latest.csv"
TRAVIS_RESULTS_DIRECTORY="/tmp/TravisResults"

libs/composer/vendor/phpunit/phpunit/phpunit --bootstrap ./libs/composer/vendor/autoload.php --configuration ./Services/PHPUnit/config/PhpUnitConfig.xml --exclude-group needsInstalledILIAS --verbose $@ | tee "$PHPUNIT_RESULTS_PATH"

if [ -e "$PHPUNIT_RESULTS_PATH" ]
	then
		echo -e "$PRE Collecting data..."
		RESULT=`tail -n1 < "$PHPUNIT_RESULTS_PATH"`
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

		echo -e "$PRE Removing old line PHP_VERSION and ILIAS_VERSION"
		grep -v "$ILIAS_VERSION.*php_$PHP_VERSION" $PHPUNIT_PATH > $PHPUNIT_PATH_TMP 

		echo -e "$PRE Writing new line"
		NEW_LINE="$JOB_URL,$JOB_ID,$ILIAS_VERSION,php_$PHP_VERSION,PHP $PHP_VERSION,${RESULTS[Warnings]},${RESULTS[Skipped]},${RESULTS[Incomplete]},${RESULTS[Tests]},${RESULTS[Errors]},${RESULTS[Risky]},$FAILURE";
		echo -e "$PRE Writing line: $NEW_LINE"
		echo -e "$NEW_LINE" >> "$PHPUNIT_PATH_TMP";

		if [ -e "$PHPUNIT_PATH_TMP" ]
			then
				mv "$PHPUNIT_PATH_TMP" "$PHPUNIT_PATH"
				rm "$PHPUNIT_RESULTS_PATH"
		fi

		echo -e "$PRE Handling result..."

		if [ -d "$TRAVIS_RESULTS_DIRECTORY" ]; then
			echo -e "$PRE Starting to remove old temp directory..."
			rm -rf "$TRAVIS_RESULTS_DIRECTORY"
		fi
		echo -e "$PRE Switching directory and clone results repository."
		cd /tmp && git clone https://github.com/vollnixx/TravisResults
		cd "$TRAVIS_RESULTS_DIRECTORY" && ./run.sh
else
	echo -e "$PRE No result file found, stopping!"
	exit 99
fi