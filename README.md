# base32-bash
Base32 encoding / decoding, written in bash with minimal dependencies

Usage:
  base32.sh [-d] < input > output

This script requires only sed in addition to the magic that is bash. It may prove to be useful if you
need this facility on a machine, or appliance, where you are not able or permitted to install packages.

As an aside, this work was created to help auto-provisioning of Google Authenicator users on an F5 LTM,
where it was used to base32-encode a ten character random string to provide the necessary TOTP secret.

Based heavily on base64.sh that was found here: http://vladz.devzero.fr/005_base64.html
