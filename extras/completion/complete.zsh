#compdef http
# ------------------------------------------------------------------------------
# Copyright (c) 2015 Github zsh-users - http://github.com/zsh-users
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the zsh-users nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL ZSH-USERS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ------------------------------------------------------------------------------
# Description
# -----------
#
#  Completion script for httpie 0.7.2  (http://httpie.org)
#
# ------------------------------------------------------------------------------
# Authors
# -------
#
#  * Akira Maeda <https://github.com/glidenote>
#  * Valodim <https://github.com/Valodim>
#  * Claus Klingberg <https://github.com/cjk>
#  * Shohei YOSHIDA <https://github.com/syohex>
#
# ------------------------------------------------------------------------------

_httpie_params () {

    local ret=1 expl

    # or a url
    if (( CURRENT <= NORMARG+1 )) && [[ $words[NORMARG] != *:* ]] ; then
        _httpie_urls && ret=0

        # regular param, if we already have a url
    elif (( CURRENT > NORMARG )); then
        # ignore all prefix stuff
        compset -P '(#b)([^:@=]#)'
        local name=$match[1]

        if false; then
            false;
        elif compset -P ':'; then
            _message "$name {option_name}"
        elif compset -P '=='; then
            _message "$name {option_name}"
        elif compset -P '='; then
            _message "$name {option_name}"
        elif compset -P ':='; then
            _message "$name {option_name}"
        elif compset -P '@'; then
            _files
        else
            typeset -a ops
            ops=(
                '\::Arbitrary HTTP header, e.g X-API-Token:123'
                '==:Querystring parameter to the URL, e.g limit==50'
                '=:Data fields to be serialized as JSON (default) or Form Data (with --form)'
                '\:=:Data field for real JSON types.'
                '@:Path field for uploading a file.'
            )
            _describe -t httpparams "parameter types" ops -Q -S ''
        fi

        ret=0

    fi

    # first arg may be a request method
    (( CURRENT == NORMARG )) &&
    _wanted http_method expl 'Request Method' \
        compadd GET POST PUT DELETE HEAD OPTIONS TRACE CONNECT PATCH LINK UNLINK && ret=0

    return $ret

}

_httpie_urls() {

    local ret=1

    if ! [[ -prefix [-+.a-z0-9]#:// ]]; then
        local expl
        compset -S '[^:/]*' && compstate[to_end]=''
        _wanted url-schemas expl 'URL schema' compadd -S '' http:// https:// && ret=0
    else
        _urls && ret=0
    fi

    return $ret

}

_httpie_printflags () {

    local ret=1

    # not sure why this is necessary, but it will complete "-pH" style without it
    [[ $IPREFIX == "-p" ]] && IPREFIX+=" "

    compset -P '(#b)([a-zA-Z]#)'

    local -a flags
    [[ $match[1] != *H* ]] && flags+=( "H:request headers" )
    [[ $match[1] != *B* ]] && flags+=( "B:request body" )
    [[ $match[1] != *h* ]] && flags+=( "h:response headers" )
    [[ $match[1] != *b* ]] && flags+=( "b:response body" )
    [[ $match[1] != *m* ]] && flags+=( "b:response meta" )

    _describe -t printflags "print flags" flags -S '' && ret=0

    return $ret

}

integer NORMARG

_arguments -n -C -s \
    {--json,-j}'[(default) Serialize data items from the command line as a JSON object.]' \
    {--form,-f}'[Serialize data items from the command line as form field data.]' \
    '--multipart[Similar to --form, but always sends a multipart/form-data request (i.e., even without files).]' \
    '--boundary=[Specify a custom boundary string for multipart/form-data requests. Only has effect only together with --form.]' \
    '--raw=[Pass raw request data without extra processing.]' \
    {--compress,-x}'[Compress the content with Deflate algorithm.]' \
    '--pretty=[Control the processing of console outputs.]:PRETTY:(all colors format none)' \
    {--style,-s}'=[Output coloring style (default is "auto").]:STYLE:' \
    '--unsorted[Disables all sorting while formatting output.]' \
    '--sorted[Re-enables all sorting options while formatting output.]' \
    '--response-charset=[Override the response encoding for terminal display purposes.]:ENCODING:' \
    '--response-mime=[Override the response mime type for coloring and formatting for the terminal.]:MIME_TYPE:' \
    '--format-options=[Controls output formatting.]' \
    {--print,-p}'=[Options to specify what the console output should contain.]:WHAT:' \
    {--headers,-h}'[Print only the response headers.]' \
    {--meta,-m}'[Print only the response metadata.]' \
    {--body,-b}'[Print only the response body.]' \
    {--verbose,-v}'[Make output more verbose.]' \
    '--all[Show any intermediary requests/responses.]' \
    {--history-print,-P}'=[--print for intermediary requests/responses.]:WHAT:' \
    {--stream,-S}'[Always stream the response body by line, i.e., behave like `tail -f`.]' \
    {--output,-o}'=[Save output to FILE instead of stdout.]:FILE:' \
    {--download,-d}'[Download the body to a file instead of printing it to stdout.]' \
    {--continue,-c}'[Resume an interrupted download (--output needs to be specified).]' \
    {--quiet,-q}'[Do not print to stdout or stderr, except for errors and warnings when provided once.]' \
    '--session=[Create, or reuse and update a session.]:SESSION_NAME_OR_PATH:' \
    '--session-read-only=[Create or read a session without updating it]:SESSION_NAME_OR_PATH:' \
    {--auth,-a}'=[Credentials for the selected (-A) authentication method.]:USER[\:PASS] | TOKEN:' \
    {--auth-type,-A}'=[The authentication mechanism to be used.]' \
    '--ignore-netrc[Ignore credentials from .netrc.]' \
    '--offline[Build the request and print it but don’t actually send it.]' \
    '--proxy=[String mapping of protocol to the URL of the proxy.]:PROTOCOL\:PROXY_URL:' \
    {--follow,-F}'[Follow 30x Location redirects.]' \
    '--max-redirects=[The maximum number of redirects that should be followed (with --follow).]' \
    '--max-headers=[The maximum number of response headers to be read before giving up (default 0, i.e., no limit).]' \
    '--timeout=[The connection timeout of the request in seconds.]:SECONDS:' \
    '--check-status[Exit with an error status code if the server replies with an error.]' \
    '--path-as-is[Bypass dot segment (/../ or /./) URL squashing.]' \
    '--chunked[Enable streaming via chunked transfer encoding. The Transfer-Encoding header is set to chunked.]' \
    '--verify=[If "no", skip SSL verification. If a file path, use it as a CA bundle.]' \
    '--ssl=[The desired protocol version to used.]:SSL:(ssl2.3 tls1 tls1.1 tls1.2)' \
    '--ciphers=[A string in the OpenSSL cipher list format.]' \
    '--cert=[Specifys a local cert to use as client side SSL certificate.]' \
    '--cert-key=[The private key to use with SSL. Only needed if --cert is given.]' \
    '--cert-key-pass=[The passphrase to be used to with the given private key.]' \
    {--ignore-stdin,-I}'[Do not attempt to read stdin]' \
    '--help[Show this help message and exit.]' \
    '--manual[Show the full manual.]' \
    '--version[Show version and exit.]' \
    '--traceback[Prints the exception traceback should one occur.]' \
    '--default-scheme=[The default scheme to use if not specified in the URL.]' \
    '--debug[Print useful diagnostic information for bug reports.]' \
    '*:args:_httpie_params' && return 0

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et
