#!/bin/bash
# Version: 1.0.2
# Usage:
# oci-curl <host> <method> [file-to-send-as-body] <request-target> [extra-curl-args]
#
# ex:
# oci-curl iaas.us-ashburn-1.oraclecloud.com get "/20160918/instances?compartmentId=some-compartment-ocid"
# oci-curl iaas.us-ashburn-1.oraclecloud.com post ./request.json "/20160918/vcns"

function oci-curl() {
    # TODO: update these values to your own
    local tenancyId="ocid1.tenancy.oc1..aaaaaaaa6kb2n4qzopn3yuql74xyfsouotlgnhcu3faa44h4vx5il3pj6fea"
    # dyangcht - CTBC
    # local authUserId="ocid1.user.oc1..aaaaaaaa5qcbhxlqjdqrdv54dlgdmxjbeggzl7r6y4qcoysyuo5tnpzqav7a"
    # Mike Lin - CTBC
    local authUserId="ocid1.user.oc1..aaaaaaaa2podbzkgjlglx3nl4ibgzff34srxw4hg3qegcibg3e7s7stmhq3q"
    local keyFingerprint="fa:c1:e7:8d:42:93:8c:2c:10:aa:7c:e7:17:28:31:49"
    local privateKeyPath="/Users/dyangcht/.oci/umc_api_key.pem"
    # local authUserId="ocid1.user.oc1..aaaaaaaammjhusnprfgvr2zf6wew3j5budtppnxus4jod4tqfqmohnc4b7va";
    # local keyFingerprint="bf:d6:a3:ce:14:7c:d1:89:36:b3:5f:7d:63:19:87:09";
    # local privateKeyPath="./oci_api_key.pem";
    # local keyFingerprint="6f:ac:d1:53:83:4b:5b:f1:ad:58:38:88:1c:0e:af:07"    # need phrase
    # local privateKeyPath="/Users/dyangcht/Dropbox/Corp/Keys/oci_api_key.pem"  # need phrase
    # local privateKeyPath="/Users/dyangcht/Dropbox/Corp/FY20/Events/HOLs/IasC/MySQL/keys/oci_api_key"
    # local keyFingerprint="6f:ac:d1:53:83:4b:5b:f1:ad:58:38:88:1c:0e:af:07"

    local alg=rsa-sha256
    local sigVersion="1"
    local now="$(LC_ALL=C \date -u "+%a, %d %h %Y %H:%M:%S GMT")"
    local host=$1
    local method=$2
    local extra_args
    local keyId="$tenancyId/$authUserId/$keyFingerprint"

    case $method in

    "get" | "GET")
        local target=$3
        extra_args=("${@:4}")
        local curl_method="GET"
        local request_method="get"
        ;;

    "delete" | "DELETE")
        local target=$3
        extra_args=("${@:4}")
        local curl_method="DELETE"
        local request_method="delete"
        ;;

    "head" | "HEAD")
        local target=$3
        extra_args=("--head" "${@:4}")
        local curl_method="HEAD"
        local request_method="head"
        ;;

    "post" | "POST")
        local body=$3
        local target=$4
        extra_args=("${@:5}")
        local curl_method="POST"
        local request_method="post"
        local content_sha256="$(openssl dgst -binary -sha256 <$body | openssl enc -e -base64)"
        local content_type="application/json"
        local content_length="$(wc -c <$body | xargs)"
        ;;

    "put" | "PUT")
        local body=$3
        local target=$4
        extra_args=("${@:5}")
        local curl_method="PUT"
        local request_method="put"
        local content_sha256="$(openssl dgst -binary -sha256 <$body | openssl enc -e -base64)"
        local content_type="application/json"
        local content_length="$(wc -c <$body | xargs)"
        ;;

    *)
        echo "invalid method"
        return
        ;;
    esac

    # This line will url encode all special characters in the request target except "/", "?", "=", and "&", since those characters are used
    # in the request target to indicate path and query string structure. If you need to encode any of "/", "?", "=", or "&", such as when
    # used as part of a path value or query string key or value, you will need to do that yourself in the request target you pass in.

    local escaped_target="$(echo $(rawurlencode "$target"))"
    # echo $escaped_target
    local request_target="(request-target): $request_method $escaped_target"
    local date_header="date: $now"
    local host_header="host: $host"
    local content_sha256_header="x-content-sha256: $content_sha256"
    local content_type_header="content-type: $content_type"
    local content_length_header="content-length: $content_length"
    local signing_string="$request_target\n$date_header\n$host_header"
    local headers="(request-target) date host"
    local curl_header_args
    curl_header_args=(-H "$date_header")
    local body_arg
    body_arg=()

    if [ "$curl_method" = "PUT" -o "$curl_method" = "POST" ]; then
        signing_string="$signing_string\n$content_sha256_header\n$content_type_header\n$content_length_header"
        headers=$headers" x-content-sha256 content-type content-length"
        curl_header_args=("${curl_header_args[@]}" -H "$content_sha256_header" -H "$content_type_header" -H "$content_length_header")
        body_arg=(--data-binary @${body})
    fi

    local sig=$(printf '%b' "$signing_string" |
        openssl dgst -sha256 -sign $privateKeyPath |
        openssl enc -e -base64 | tr -d '\n')

    echo "extra: " "${curl_header_args[@]}"
    curl "${extra_args[@]}" "${body_arg[@]}" -k -X $curl_method -sS https://${host}${escaped_target} "${curl_header_args[@]}" \
        -H "Authorization: Signature version=\"$sigVersion\",keyId=\"$keyId\",algorithm=\"$alg\",headers=\"${headers}\",signature=\"$sig\""
}
# url encode all special characters except "/", "?", "=", and "&"
function rawurlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for ((pos = 0; pos < strlen; pos++)); do
        c=${string:$pos:1}
        case "$c" in
        [-_.~a-zA-Z0-9] | "/" | "?" | "=" | "&") o="${c}" ;;
        *) printf -v o '%%%02x' "'$c" ;;
        esac
        encoded+="${o}"
    done

    echo "${encoded}"
}

# echo "Get root subnet..."
# oci-curl iaas.us-ashburn-1.oraclecloud.com get "/20160918/subnets?compartmentId=ocid1.tenancy.oc1..aaaaaaaa6kb2n4qzopn3yuql74xyfsouotlgnhcu3faa44h4vx5il3pj6fea&vcnId=ocid1.vcn.oc1.iad.amaaaaaada5axoiajogthtjylikcp7uyu6npococoul3w4vd6hyl2uj4k4lq"
# echo ""
# echo ""
# echo -e "\033[35mGet workshop1 subnet...\033[0m"
# oci-curl iaas.us-ashburn-1.oraclecloud.com get "/20160918/subnets?compartmentId=ocid1.compartment.oc1..aaaaaaaafhxy4cadtxlpq4virakdss24u5t3zll2sbb5pzmmoze7baqsphtq&vcnId=ocid1.vcn.oc1.iad.amaaaaaada5axoiag5xn5k25eqtyfnw6fi43a6qvvi2fgwh2zlzidoypn6eq"
# echo ""
# echo -e "\033[35mCreating User...\033[0m"
# oci-curl identity.us-ashburn-1.oraclecloud.com post "request.json" "/20160918/users/"
# echo ""
# echo ""
echo -e "\033[35mCreating VCN under mike_lin...\033[0m"
# 1. get availability domain first
# oci-curl identity.us-ashburn-1.oraclecloud.com get "/20160918/availabilityDomains?compartmentId=ocid1.compartment.oc1..aaaaaaaadromjyzkt6f24wdtkxhpzovrvuuqt7keenqd4bryfhpay7ikotka"
# 2. create VCN
# oci-curl iaas.us-ashburn-1.oraclecloud.com post "vcn.json" "/20160918/vcns/"
# 3. create subnets, if you want to create regional subnet then don't put the option "availabilityDomain"
# in the subnet.json file
# oci-curl iaas.us-ashburn-1.oraclecloud.com post "subnet.json" "/20160918/subnets/"
# 4. create a internet gateway
# oci-curl iaas.us-ashburn-1.oraclecloud.com post "igw.json" "/20160918/internetGateways/"
# 5. create a public route table
# oci-curl iaas.us-ashburn-1.oraclecloud.com post "routetable.json" "/20160918/routeTables/"
# 6. get shape name
# oci-curl iaas.us-ashburn-1.oraclecloud.com get "/20160918/shapes?compartmentId=ocid1.compartment.oc1..aaaaaaaadromjyzkt6f24wdtkxhpzovrvuuqt7keenqd4bryfhpay7ikotka"
# 7. create a new instance
# oci-curl iaas.us-ashburn-1.oraclecloud.com post "instance.json" "/20160918/instances"
echo -e "\n\n\n"
# compartment: mike_lin
# oci-curl iaas.us-ashburn-1.oraclecloud.com get "/20160918/vcns?compartmentId=ocid1.compartment.oc1..aaaaaaaadromjyzkt6f24wdtkxhpzovrvuuqt7keenqd4bryfhpay7ikotka"
# oci-curl iaas.us-ashburn-1.oraclecloud.com get "/20160918/users/ocid1.user.oc1..aaaaaaaammjhusnprfgvr2zf6wew3j5budtppnxus4jod4tqfqmohnc4b7va/apiKeys/"
# oci-curl iaas.us-ashburn-1.oraclecloud.com get "/20160918/users/ocid1.user.oc1..aaaaaaaaelmcbbmzggwgwn6irdz3bt6duekxcdk567sbyrn5nnuqaxce2qya/apiKeys/"
# uu=echo $(rawurlencode "ocid1.user.oc1..aaaaaaaaelmcbbmzggwgwn6irdz3bt6duekxcdk567sbyrn5nnuqaxce2qya")
# oci-curl iaas.us-ashburn-1.oraclecloud.com get "/20160918/users/${uu}/apiKeys/"
# oci-curl containerengine.us-ashburn-1.oraclecloud.com get "/20180222/clusters/ocid1.cluster.oc1.iad.aaaaaaaaae4gcndggu3dambygnsggntbmrqwmnztmq3gmmzugcytgzbvmrsd/kubeconfig/content"
