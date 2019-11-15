#This includes code from https://github.com/nfsn/lets-nfsn.sh and
# https://gist.github.com/nmschulte/9514bef23fc416b4b87f

# The below three variables need to be set.  API keys are available on request
# (and for free) via NFSN support section.  DOMAINROOT is the root of your
# domain.  For example, I use "pressers.name".

# Also, see line 56, which is the place to make modifications if you wish to
# do anything with the key after getting it.
LOGIN=
API_KEY=
DOMAINROOT=

make_request () {
    TIMESTAMP=$(date +%s)
    SALT=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 16)
    REQUEST_URI="$1"

    if [ "$#" -gt "1" ]; then
        PARAMETERS="$2"
    fi  

    COUNT=3
    while test $COUNT -le $#
    do
        eval "PARAMETER=\$$COUNT"
        PARAMETERS="$PARAMETERS&$PARAMETER"
        COUNT=$((COUNT + 1))
    done

    BODY=$PARAMETERS
    BODY_HASH=$(printf "%s" "$BODY" | sha1sum | awk '{print $1}')
    HASH_STRING=$(printf "%s" "$LOGIN;$TIMESTAMP;$SALT;$API_KEY;$REQUEST_URI;$BODY_HASH")
    HASH=$(printf "%s" "$HASH_STRING" | sha1sum | awk '{print $1}')

    curl -s -o - -k -X POST -H "X-NFSN-Authentication: $LOGIN;$TIMESTAMP;$SALT;$HASH" -d "$BODY" "https://api.nearlyfreespeech.net$REQUEST_URI"
}

function deploy_challenge {
	local DOMAIN="$(basename ${1} .${DOMAINROOT})" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
	echo " + Deploying challenge"
	make_request "/dns/${DOMAINROOT}/addRR" "name=_acme-challenge.${DOMAIN}" "type=TXT" "data=${TOKEN_VALUE}"
}


function clean_challenge {
	local DOMAIN="$(basename ${1} .${DOMAINROOT})" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
	echo " + Cleaning challenge"
	make_request "/dns/${DOMAINROOT}/removeRR" "name=_acme-challenge.${DOMAIN}" "type=TXT" "data=${TOKEN_VALUE}"
}


function deploy_cert {
	local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"
	echo " + Installing new certificate for ${DOMAIN}..."
	# If you need to move or change permissions of the key after generation, do so here
}


function invalid_challenge {
	local DOMAIN="${1}" RESULT="${2}"
	echo " + Certificate for ${DOMAIN} had invalid challenge. Result follows:"
	printf '%s\n' "${RESULT}"
}


function unchanged_cert {
	local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
	echo " + Certificate for ${DOMAIN} unchanged."
}


function function_exists() {
	declare -f "${1}" >/dev/null
	return $?
}

HANDLER="$1"; shift;

if function_exists "$HANDLER"
then
	"$HANDLER" "$@"
fi
