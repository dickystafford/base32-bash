#!/bin/bash
# base32.sh -- Bash implementation of the Base32 encoding and decoding scheme
#
# February 2016 DickyS
#
# Encode or decode original Base32 (and also base32hex) from standard input
# to standard output
#
# Usage:
#
#    Encode and decode a binary file:
#    $ ./base32.sh < binary-file > binary-file.base32
#    $ ./base32.sh -d < binary-file.base32 > binary-file
#
# Reference:
#
#    [1]  RFC4648 - "The Base16, Base32, and Base64 Data Encodings"
#         http://tools.ietf.org/html/rfc4648#section-6

# base32_charset[] array contains entire base32 charset and the padding
# character "="
base32_charset=( {A..Z} {2..7} = )

# base32_charset[] array contains entire base32hex charset and the padding
# character "="
#base32_charset=( {0..9} {A..V} = )

# output text width when encoding (64 characters is like openssl's output)
text_width=64

# encode five 8-bit hexadecimal codes into eight 5-bit numbers
function encode_base32 {

  # need two local int array variables:
  # c8[]: to store the codes of the 8-bit characters to encode
  # c5[]: to store the corresponding encoded values on 5-bit
  declare -a -i c8 c5

  # convert string to ASCII decimal
  c8=( $(for((i=0; i<${#1}; i++)); do printf '%d ' "'${1:i:1}'"; done) )

  # let's play with bitwise operators (5x8-bit into 8x5-bits conversion)
  (( c5[0] = c8[0] >> 3 ))
  (( c5[1] = ((c8[0] & 7) << 2 ) | (c8[1] >> 6) ))
  (( c5[2] = (c8[1] & 62) >> 1 ))
  (( c5[3] = ((c8[1] & 1) << 4) | ((c8[2] & 240) >> 4) ))
  (( c5[4] = ((c8[2] & 15) << 1) | (c8[3] >> 7) ))
  (( c5[5] = (c8[3] & 124 ) >> 2 ))
  (( c5[6] = ((c8[3] & 3) << 3) | ((c8[4] & 224) >> 5) ))
  (( c5[7] = c8[4] & 31 ))

  # add padding
  case ${#c8[*]} in
    1) (( c5[7] = c5[6] = c5[5] = c5[4] =c5[3] = c5[2] = 32 )) ;;
    2) (( c5[7] = c5[6] = c5[5] = c5[4] = 32 )) ;;
    3) (( c5[7] = c5[6] = c5[5] = 32 )) ;;
    4) (( c5[7] = 32 )) ;;
  esac

  for char in ${c5[@]}; do
    # convert a 5-bit number (between 0 and 31, plus padding) into its corresponding values
    # in Base32, and display the result with the predefined text width
    printf "${base32_charset[$char]}"; (( width++ ))
    (( width % text_width == 0 )) && printf "\n"
  done
}

# decode eight base32 characters into five hexadecimal ASCII characters
function decode_base32 {

  # c8[]: to store the codes of the 8-bit characters
  # c5[]: to store the corresponding Base32 values on 5-bit
  declare -a -i c8 c5

  # find decimal value corresponding to the current base32 character
  for current_char in $(echo $1 | grep -o .); do
     [ "${current_char}" = "=" ] && break

     # get position in array, insert newlines to cope with grep 2.5.1 byte-offset bug
     twicepos="$(echo ${base32_charset[*]} | sed -e 's/ /\n/g' | grep -b ${current_char} | sed -e 's/:.*$//')"

     if [[ -n $twicepos ]]; then
       c5=( ${c5[*]} "$(expr $twicepos / 2)" )
     else
       echo -e "\nERROR: Invalid character '${current_char}' in input. Decode aborted."
       exit
     fi

  done

  # let's play with bitwise operators (8x5-bit into 5x8-bits conversion)
  (( c8[0] = (c5[0] << 3) | ((c5[1] & 28 ) >> 2) ))
  (( c8[1] = ((c5[1] & 3) << 6) | (c5[2] << 1) | ((c5[3] & 16) >> 4) ))
  (( c8[2] = ((c5[3] & 15) << 4) | ((c5[4] & 30) >> 1) ))
  (( c8[3] = ((c5[4] & 1) << 7) | (c5[5] << 2) | ((c5[6] & 24) >> 3) ))
  (( c8[4] = ((c5[6] & 7) << 5) | c5[7] ))

  for char in ${c8[*]}; do
     printf "\x$(printf "%x" ${char})"
  done
}

# main
if [ $# -eq 0 ]; then   # encode

  # reformat in 5-byte groups
  content=$(cat - | sed -r "s/(\w{5})/\1 /g;s/\n//g")

  for chars in ${content}; do encode_base32 ${chars}; done; echo

elif [ "$1" = "-d" ]; then   # decode

  # reformat stdin in pseudo "8x5-bit" groups
  content=$(cat - | sed -r "s/\n//g;s/(.{8})/\1 /g")

  for chars in ${content}; do decode_base32 ${chars}; done; echo

else   # display usage

  printf "usage: $0 [-d]\n\n  -d\tdecode instead of encode\n\n"

fi
