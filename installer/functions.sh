# no shebang necessary - this is a library to be sourced
# SPDX-License-Identifier: GPL-3.0+

# make sure we have a UID
[ -z "${UID}" ] && UID="$(id -u)"


# -----------------------------------------------------------------------------
# checking the availability of commands

which_cmd() {
    which "${1}" 2>/dev/null || \
        command -v "${1}" 2>/dev/null
}

check_cmd() {
    which_cmd "${1}" >/dev/null 2>&1 && return 0
    return 1
}


# -----------------------------------------------------------------------------

setup_terminal() {
    TPUT_RESET=""
    TPUT_BLACK=""
    TPUT_RED=""
    TPUT_GREEN=""
    TPUT_YELLOW=""
    TPUT_BLUE=""
    TPUT_PURPLE=""
    TPUT_CYAN=""
    TPUT_WHITE=""
    TPUT_BGBLACK=""
    TPUT_BGRED=""
    TPUT_BGGREEN=""
    TPUT_BGYELLOW=""
    TPUT_BGBLUE=""
    TPUT_BGPURPLE=""
    TPUT_BGCYAN=""
    TPUT_BGWHITE=""
    TPUT_BOLD=""
    TPUT_DIM=""
    TPUT_UNDERLINED=""
    TPUT_BLINK=""
    TPUT_INVERTED=""
    TPUT_STANDOUT=""
    TPUT_BELL=""
    TPUT_CLEAR=""

    # Is stderr on the terminal? If not, then fail
    test -t 2 || return 1

    if check_cmd tput
    then
        if [ $(( $(tput colors 2>/dev/null) )) -ge 8 ]
        then
            # Enable colors
            TPUT_RESET="$(tput sgr 0)"
            TPUT_BLACK="$(tput setaf 0)"
            TPUT_RED="$(tput setaf 1)"
            TPUT_GREEN="$(tput setaf 2)"
            TPUT_YELLOW="$(tput setaf 3)"
            TPUT_BLUE="$(tput setaf 4)"
            TPUT_PURPLE="$(tput setaf 5)"
            TPUT_CYAN="$(tput setaf 6)"
            TPUT_WHITE="$(tput setaf 7)"
            TPUT_BGBLACK="$(tput setab 0)"
            TPUT_BGRED="$(tput setab 1)"
            TPUT_BGGREEN="$(tput setab 2)"
            TPUT_BGYELLOW="$(tput setab 3)"
            TPUT_BGBLUE="$(tput setab 4)"
            TPUT_BGPURPLE="$(tput setab 5)"
            TPUT_BGCYAN="$(tput setab 6)"
            TPUT_BGWHITE="$(tput setab 7)"
            TPUT_BOLD="$(tput bold)"
            TPUT_DIM="$(tput dim)"
            TPUT_UNDERLINED="$(tput smul)"
            TPUT_BLINK="$(tput blink)"
            TPUT_INVERTED="$(tput rev)"
            TPUT_STANDOUT="$(tput smso)"
            TPUT_BELL="$(tput bel)"
            TPUT_CLEAR="$(tput clear)"
        fi
    fi

    return 0
}
setup_terminal || echo >/dev/null

progress() {
    echo >&2 " --- ${TPUT_DIM}${TPUT_BOLD}${*}${TPUT_RESET} --- "
}

# -----------------------------------------------------------------------------

hibenchmarks_banner() {
    local   l1="  ^"                                                                            \
            l2="  |.-.   .-.   .-.   .-.   .-.   .-.   .-.   .-.   .-.   .-.   .-.   .-.   .-"  \
            l3="  |   '-'   '-'   '-'   '-'   '-'   '-'   '-'   '-'   '-'   '-'   '-'   '-'  "  \
            l4="  +----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+--->" \
            sp="                                                                              " \
            hibenchmarks="hibenchmarks" start end msg="${*}" chartcolor="${TPUT_DIM}"

    [ ${#msg} -lt ${#hibenchmarks} ] && msg="${msg}${sp:0:$(( ${#hibenchmarks} - ${#msg}))}"
    [ ${#msg} -gt $(( ${#l2} - 20 )) ] && msg="${msg:0:$(( ${#l2} - 23 ))}..."

    start="$(( ${#l2} / 2 - 4 ))"
    [ $(( start + ${#msg} + 4 )) -gt ${#l2} ] && start=$((${#l2} - ${#msg} - 4))
    end=$(( ${start} + ${#msg} + 4 ))

    echo >&2
    echo >&2 "${chartcolor}${l1}${TPUT_RESET}"
    echo >&2 "${chartcolor}${l2:0:start}${sp:0:2}${TPUT_RESET}${TPUT_BOLD}${TPUT_GREEN}${hibenchmarks}${TPUT_RESET}${chartcolor}${sp:0:$((end - start - 2 - ${#hibenchmarks}))}${l2:end:$((${#l2} - end))}${TPUT_RESET}"
    echo >&2 "${chartcolor}${l3:0:start}${sp:0:2}${TPUT_RESET}${TPUT_BOLD}${TPUT_CYAN}${msg}${TPUT_RESET}${chartcolor}${sp:0:2}${l3:end:$((${#l2} - end))}${TPUT_RESET}"
    echo >&2 "${chartcolor}${l4}${TPUT_RESET}"
    echo >&2
}

# -----------------------------------------------------------------------------
# portable service command

service_cmd="$(which_cmd service)"
rcservice_cmd="$(which_cmd rc-service)"
systemctl_cmd="$(which_cmd systemctl)"
service() {
    local cmd="${1}" action="${2}"

    if [ ! -z "${systemctl_cmd}" ]
    then
        run "${systemctl_cmd}" "${action}" "${cmd}"
        return $?
    elif [ ! -z "${service_cmd}" ]
    then
        run "${service_cmd}" "${cmd}" "${action}"
        return $?
    elif [ ! -z "${rcservice_cmd}" ]
    then
        run "${rcservice_cmd}" "${cmd}" "${action}"
        return $?
    fi
    return 1
}

# -----------------------------------------------------------------------------
# portable pidof

pidof_cmd="$(which_cmd pidof)"
pidof() {
    if [ ! -z "${pidof_cmd}" ]
    then
        ${pidof_cmd} "${@}"
        return $?
    else
        ps -acxo pid,comm |\
            sed "s/^ *//g" |\
            grep hibenchmarks |\
            cut -d ' ' -f 1
        return $?
    fi
}

# -----------------------------------------------------------------------------
# portable delete recursively interactively

portable_deletedir_recursively_interactively() {
    if [ ! -z "$1" -a -d "$1" ]
        then
        if [ "$(uname -s)" = "Darwin" ]
        then
            echo >&2
            read >&2 -p "Press ENTER to recursively delete directory '$1' > "
            echo >&2 "Deleting directory '$1' ..."
            run rm -R "$1"
        else
            echo >&2
            echo >&2 "Deleting directory '$1' ..."
            run rm -I -R "$1"
        fi
    else
        echo "Directory '$1' does not exist."
    fi
}


# -----------------------------------------------------------------------------

export SYSTEM_CPUS=1
portable_find_processors() {
    if [ -f "/proc/cpuinfo" ]
    then
        # linux
        SYSTEM_CPUS=$(grep -c ^processor /proc/cpuinfo)
    else
        # freebsd
        SYSTEM_CPUS=$(sysctl hw.ncpu 2>/dev/null | grep ^hw.ncpu | cut -d ' ' -f 2)
    fi
    [ -z "${SYSTEM_CPUS}" -o $(( SYSTEM_CPUS )) -lt 1 ] && SYSTEM_CPUS=1
}
portable_find_processors

# -----------------------------------------------------------------------------

run_ok() {
    printf >&2 "${TPUT_BGGREEN}${TPUT_WHITE}${TPUT_BOLD} OK ${TPUT_RESET} ${*} \n\n"
}

run_failed() {
    printf >&2 "${TPUT_BGRED}${TPUT_WHITE}${TPUT_BOLD} FAILED ${TPUT_RESET} ${*} \n\n"
}

ESCAPED_PRINT_METHOD=
printf "%q " test >/dev/null 2>&1
[ $? -eq 0 ] && ESCAPED_PRINT_METHOD="printfq"
escaped_print() {
    if [ "${ESCAPED_PRINT_METHOD}" = "printfq" ]
    then
        printf "%q " "${@}"
    else
        printf "%s" "${*}"
    fi
    return 0
}

run_logfile="/dev/null"
run() {
    local user="${USER--}" dir="${PWD}" info info_console

    if [ "${UID}" = "0" ]
        then
        info="[root ${dir}]# "
        info_console="[${TPUT_DIM}${dir}${TPUT_RESET}]# "
    else
        info="[${user} ${dir}]$ "
        info_console="[${TPUT_DIM}${dir}${TPUT_RESET}]$ "
    fi

    printf >> "${run_logfile}" "${info}"
    escaped_print >> "${run_logfile}" "${@}"
    printf >> "${run_logfile}" " ... "

    printf >&2 "${info_console}${TPUT_BOLD}${TPUT_YELLOW}"
    escaped_print >&2 "${@}"
    printf >&2 "${TPUT_RESET}\n"

    "${@}"

    local ret=$?
    if [ ${ret} -ne 0 ]
        then
        run_failed
        printf >> "${run_logfile}" "FAILED with exit code ${ret}\n"
    else
        run_ok
        printf >> "${run_logfile}" "OK\n"
    fi

    return ${ret}
}

getent_cmd="$(which_cmd getent)"
portable_check_user_exists() {
    local username="${1}" found=

    if [ ! -z "${getent_cmd}" ]
        then
        "${getent_cmd}" passwd "${username}" >/dev/null 2>&1
        return $?
    fi

    found="$(cut -d ':' -f 1 </etc/passwd | grep "^${username}$")"
    [ "${found}" = "${username}" ] && return 0
    return 1
}

portable_check_group_exists() {
    local groupname="${1}" found=

    if [ ! -z "${getent_cmd}" ]
        then
        "${getent_cmd}" group "${groupname}" >/dev/null 2>&1
        return $?
    fi

    found="$(cut -d ':' -f 1 </etc/group | grep "^${groupname}$")"
    [ "${found}" = "${groupname}" ] && return 0
    return 1
}

portable_check_user_in_group() {
    local username="${1}" groupname="${2}" users=

    if [ ! -z "${getent_cmd}" ]
        then
        users="$(getent group "${groupname}" | cut -d ':' -f 4)"
    else
        users="$(grep "^${groupname}:" </etc/group | cut -d ':' -f 4)"
    fi

    [[ ",${users}," =~ ,${username}, ]] && return 0
    return 1
}

portable_add_user() {
    local username="${1}" homedir="${2}"

    [ -z "${homedir}" ] && homedir="/tmp"

    portable_check_user_exists "${username}"
    [ $? -eq 0 ] && echo >&2 "User '${username}' already exists." && return 0

    echo >&2 "Adding ${username} user account with home ${homedir} ..."

    local nologin="$(which nologin 2>/dev/null || command -v nologin 2>/dev/null || echo '/bin/false')"

    # Linux
    if check_cmd useradd
    then
        run useradd -r -g "${username}" -c "${username}" -s "${nologin}" --no-create-home -d "${homedir}" "${username}" && return 0
    fi

    # FreeBSD
    if check_cmd pw
    then
        run pw useradd "${username}" -d "${homedir}" -g "${username}" -s "${nologin}" && return 0
    fi

    # BusyBox
    if check_cmd adduser
    then
        run adduser -h "${homedir}" -s "${nologin}" -D -G "${username}" "${username}" && return 0
    fi

    echo >&2 "Failed to add ${username} user account !"

    return 1
}

portable_add_group() {
    local groupname="${1}"

    portable_check_group_exists "${groupname}"
    [ $? -eq 0 ] && echo >&2 "Group '${groupname}' already exists." && return 0

    echo >&2 "Adding ${groupname} user group ..."

    # Linux
    if check_cmd groupadd
    then
        run groupadd -r "${groupname}" && return 0
    fi

    # FreeBSD
    if check_cmd pw
    then
        run pw groupadd "${groupname}" && return 0
    fi

    # BusyBox
    if check_cmd addgroup
    then
        run addgroup "${groupname}" && return 0
    fi

    echo >&2 "Failed to add ${groupname} user group !"
    return 1
}

portable_add_user_to_group() {
    local groupname="${1}" username="${2}"

    portable_check_group_exists "${groupname}"
    [ $? -ne 0 ] && echo >&2 "Group '${groupname}' does not exist." && return 1

    # find the user is already in the group
    if portable_check_user_in_group "${username}" "${groupname}"
        then
        # username is already there
        echo >&2 "User '${username}' is already in group '${groupname}'."
        return 0
    else
        # username is not in group
        echo >&2 "Adding ${username} user to the ${groupname} group ..."

        # Linux
        if check_cmd usermod
        then
            run usermod -a -G "${groupname}" "${username}" && return 0
        fi

        # FreeBSD
        if check_cmd pw
        then
            run pw groupmod "${groupname}" -m "${username}" && return 0
        fi

        # BusyBox
        if check_cmd addgroup
        then
            run addgroup "${username}" "${groupname}" && return 0
        fi

        echo >&2 "Failed to add user ${username} to group ${groupname} !"
        return 1
    fi
}

iscontainer() {
    # man systemd-detect-virt
    local cmd=$(which_cmd systemd-detect-virt)
    if [ ! -z "${cmd}" -a -x "${cmd}" ]
        then
        "${cmd}" --container >/dev/null 2>&1 && return 0
    fi

    # /proc/1/sched exposes the host's pid of our init !
    # http://stackoverflow.com/a/37016302
    local pid=$( cat /proc/1/sched 2>/dev/null | head -n 1 | { IFS='(),#:' read name pid th threads; echo $pid; } )
    pid=$(( pid + 0 ))
    [ ${pid} -ne 1 ] && return 0

    # lxc sets environment variable 'container'
    [ ! -z "${container}" ] && return 0

    # docker creates /.dockerenv
    # http://stackoverflow.com/a/25518345
    [ -f "/.dockerenv" ] && return 0

    # ubuntu and debian supply /bin/running-in-container
    # https://www.apt-browse.org/browse/ubuntu/trusty/main/i386/upstart/1.12.1-0ubuntu4/file/bin/running-in-container
    if [ -x "/bin/running-in-container" ]
        then
        "/bin/running-in-container" >/dev/null 2>&1 && return 0
    fi

    return 1
}

issystemd() {
    local pids p myns ns systemctl

    # if the directory /etc/systemd/system does not exit, it is not systemd
    [ ! -d /etc/systemd/system ] && return 1

    # if there is no systemctl command, it is not systemd
    systemctl=$(which systemctl 2>/dev/null || command -v systemctl 2>/dev/null)
    [ -z "${systemctl}" -o ! -x "${systemctl}" ] && return 1

    # if pid 1 is systemd, it is systemd
    [ "$(basename $(readlink /proc/1/exe) 2>/dev/null)" = "systemd" ] && return 0

    # if systemd is not running, it is not systemd
    pids=$(pidof systemd 2>/dev/null)
    [ -z "${pids}" ] && return 1

    # check if the running systemd processes are not in our namespace
    myns="$(readlink /proc/self/ns/pid 2>/dev/null)"
    for p in ${pids}
    do
        ns="$(readlink /proc/${p}/ns/pid 2>/dev/null)"

        # if pid of systemd is in our namespace, it is systemd
        [ ! -z "${myns}" && "${myns}" = "${ns}" ] && return 0
    done

    # else, it is not systemd
    return 1
}

install_non_systemd_init() {
    [ "${UID}" != 0 ] && return 1

    local key="unknown"
    if [ -f /etc/os-release ]
        then
        source /etc/os-release || return 1
        key="${ID}-${VERSION_ID}"

    elif [ -f /etc/redhat-release ]
        then
        key=$(</etc/redhat-release)
    fi

    if [ -d /etc/init.d -a ! -f /etc/init.d/hibenchmarks ]
        then
        if [[ "${key}" =~ ^(gentoo|alpine).* ]]
            then
            echo >&2 "Installing OpenRC init file..."
            run cp system/hibenchmarks-openrc /etc/init.d/hibenchmarks && \
            run chmod 755 /etc/init.d/hibenchmarks && \
            run rc-update add hibenchmarks default && \
            return 0
        
        elif [ "${key}" = "debian-7" \
            -o "${key}" = "ubuntu-12.04" \
            -o "${key}" = "ubuntu-14.04" \
            ]
            then
            echo >&2 "Installing LSB init file..."
            run cp system/hibenchmarks-lsb /etc/init.d/hibenchmarks && \
            run chmod 755 /etc/init.d/hibenchmarks && \
            run update-rc.d hibenchmarks defaults && \
            run update-rc.d hibenchmarks enable && \
            return 0
        elif [[ "${key}" =~ ^(amzn-201[5678]|ol|CentOS release 6|Red Hat Enterprise Linux Server release 6|Scientific Linux CERN SLC release 6|CloudLinux Server release 6).* ]]
            then
            echo >&2 "Installing init.d file..."
            run cp system/hibenchmarks-init-d /etc/init.d/hibenchmarks && \
            run chmod 755 /etc/init.d/hibenchmarks && \
            run chkconfig hibenchmarks on && \
            return 0
        else
            echo >&2 "I don't know what init file to install on system '${key}'. Open a github issue to help us fix it."
            return 1
        fi
    elif [ -f /etc/init.d/hibenchmarks ]
        then
        echo >&2 "file '/etc/init.d/hibenchmarks' already exists."
        return 0
    else
        echo >&2 "I don't know what init file to install on system '${key}'. Open a github issue to help us fix it."
    fi

    return 1
}

HIBENCHMARKS_START_CMD="hibenchmarks"
HIBENCHMARKS_STOP_CMD="killall hibenchmarks"

install_hibenchmarks_service() {
    local uname="$(uname 2>/dev/null)"

    if [ "${UID}" -eq 0 ]
    then
        if [ "${uname}" = "Darwin" ]
        then

            if [ -f "/Library/LaunchDaemons/com.github.hibenchmarks.plist" ]
                then
                echo >&2 "file '/Library/LaunchDaemons/com.github.hibenchmarks.plist' already exists."
                return 0
            else
                echo >&2 "Installing MacOS X plist file..."
                run cp system/hibenchmarks.plist /Library/LaunchDaemons/com.github.hibenchmarks.plist && \
                run launchctl load /Library/LaunchDaemons/com.github.hibenchmarks.plist && \
                return 0
            fi

        elif [ "${uname}" = "FreeBSD" ]
        then

            run cp system/hibenchmarks-freebsd /etc/rc.d/hibenchmarks && \
                HIBENCHMARKS_START_CMD="service hibenchmarks start" && \
                HIBENCHMARKS_STOP_CMD="service hibenchmarks stop" && \
                return 0

        elif issystemd
        then
            # systemd is running on this system
            HIBENCHMARKS_START_CMD="systemctl start hibenchmarks"
            HIBENCHMARKS_STOP_CMD="systemctl stop hibenchmarks"

            if [ ! -f /etc/systemd/system/hibenchmarks.service ]
            then
                echo >&2 "Installing systemd service..."
                run cp system/hibenchmarks.service /etc/systemd/system/hibenchmarks.service && \
                    run systemctl daemon-reload && \
                    run systemctl enable hibenchmarks && \
                    return 0
            else
                echo >&2 "file '/etc/systemd/system/hibenchmarks.service' already exists."
                return 0
            fi
        else
            install_non_systemd_init
            local ret=$?

            if [ ${ret} -eq 0 ]
            then
                if [ ! -z "${service_cmd}" ]
                then
                    HIBENCHMARKS_START_CMD="service hibenchmarks start"
                    HIBENCHMARKS_STOP_CMD="service hibenchmarks stop"
                elif [ ! -z "${rcservice_cmd}" ]
                then
                    HIBENCHMARKS_START_CMD="rc-service hibenchmarks start"
                    HIBENCHMARKS_STOP_CMD="rc-service hibenchmarks stop"
                fi
            fi

            return ${ret}
        fi
    fi

    return 1
}


# -----------------------------------------------------------------------------
# stop hibenchmarks

pidishibenchmarks() {
    if [ -d /proc/self ]
    then
        [ -z "$1" -o ! -f "/proc/$1/stat" ] && return 1
        [ "$(cat "/proc/$1/stat" | cut -d '(' -f 2 | cut -d ')' -f 1)" = "hibenchmarks" ] && return 0
        return 1
    fi
    return 0
}

stop_hibenchmarks_on_pid() {
    local pid="${1}" ret=0 count=0

    pidishibenchmarks ${pid} || return 0

    printf >&2 "Stopping hibenchmarks on pid ${pid} ..."
    while [ ! -z "$pid" -a ${ret} -eq 0 ]
    do
        if [ ${count} -gt 45 ]
            then
            echo >&2 "Cannot stop the running hibenchmarks on pid ${pid}."
            return 1
        fi

        count=$(( count + 1 ))

        run kill ${pid} 2>/dev/null
        ret=$?

        test ${ret} -eq 0 && printf >&2 "." && sleep 2
    done

    echo >&2
    if [ ${ret} -eq 0 ]
    then
        echo >&2 "SORRY! CANNOT STOP hibenchmarks ON PID ${pid} !"
        return 1
    fi

    echo >&2 "hibenchmarks on pid ${pid} stopped."
    return 0
}

hibenchmarks_pids() {
    local p myns ns

    myns="$(readlink /proc/self/ns/pid 2>/dev/null)"

    # echo >&2 "Stopping a (possibly) running hibenchmarks (namespace '${myns}')..."

    for p in \
        $(cat /var/run/hibenchmarks.pid 2>/dev/null) \
        $(cat /var/run/hibenchmarks/hibenchmarks.pid 2>/dev/null) \
        $(pidof hibenchmarks 2>/dev/null)
    do
        ns="$(readlink /proc/${p}/ns/pid 2>/dev/null)"

        if [ -z "${myns}" -o -z "${ns}" -o "${myns}" = "${ns}" ]
            then
            pidishibenchmarks ${p} && echo "${p}"
        fi
    done
}

stop_all_hibenchmarks() {
    local p
    for p in $(hibenchmarks_pids)
    do
        stop_hibenchmarks_on_pid ${p}
    done
}

# -----------------------------------------------------------------------------
# restart hibenchmarks

restart_hibenchmarks() {
    local hibenchmarks="${1}"
    shift

    local started=0

    progress "Start hibenchmarks"

    if [ "${UID}" -eq 0 ]
        then
        service hibenchmarks stop
        stop_all_hibenchmarks
        service hibenchmarks restart && started=1

        if [ ${started} -eq 1 -a -z "$(hibenchmarks_pids)" ]
        then
            echo >&2 "Ooops! it seems hibenchmarks is not started."
            started=0
        fi

        if [ ${started} -eq 0 ]
        then
            service hibenchmarks start && started=1
        fi
    fi

    if [ ${started} -eq 1 -a -z "$(hibenchmarks_pids)" ]
    then
        echo >&2 "Hm... it seems hibenchmarks is still not started."
        started=0
    fi

    if [ ${started} -eq 0 ]
    then
        # still not started...

        run stop_all_hibenchmarks
        run "${hibenchmarks}" "${@}"
        return $?
    fi

    return 0
}

# -----------------------------------------------------------------------------
# install hibenchmarks logrotate

install_hibenchmarks_logrotate() {
    if [ ${UID} -eq 0 ]
        then
        if [ -d /etc/logrotate.d ]
            then
            if [ ! -f /etc/logrotate.d/hibenchmarks ]
                then
                run cp system/hibenchmarks.logrotate /etc/logrotate.d/hibenchmarks
            fi
            
            if [ -f /etc/logrotate.d/hibenchmarks ]
                then
                run chmod 644 /etc/logrotate.d/hibenchmarks
            fi

            return 0
        fi
    fi
    
    return 1
}

# -----------------------------------------------------------------------------
# download hibenchmarks.conf

fix_hibenchmarks_conf() {
    local owner="${1}"

    if [ "${UID}" -eq 0 ]
        then
        run chown "${owner}" "${filename}"
    fi
    run chmod 0664 "${filename}"
}

generate_hibenchmarks_conf() {
    local owner="${1}" filename="${2}" url="${3}"

    if [ ! -s "${filename}" ]
        then
        cat >"${filename}" <<EOFCONF
# hibenchmarks can generate its own config.
# Get it with:
#
# wget -O ${filename} "${url}"
#
# or
#
# curl -s -o ${filename} "${url}"
#
EOFCONF
        fix_hibenchmarks_conf "${owner}"
    fi
}

download_hibenchmarks_conf() {
    local owner="${1}" filename="${2}" url="${3}"

    if [ ! -s "${filename}" ]
        then
        echo >&2
        echo >&2 "-------------------------------------------------------------------------------"
        echo >&2
        echo >&2 "Downloading default configuration from hibenchmarks..."
        sleep 5

        # remove a possibly obsolete download
        [ -f "${filename}.new" ] && rm "${filename}.new"

        # disable a proxy to get data from the local hibenchmarks
        export http_proxy=
        export https_proxy=

        # try curl
        run curl -s -o "${filename}.new" "${url}"
        ret=$?

        if [ ${ret} -ne 0 -o ! -s "${filename}.new" ]
            then
            # try wget
            run wget -O "${filename}.new" "${url}"
            ret=$?
        fi

        if [ ${ret} -eq 0 -a -s "${filename}.new" ]
            then
            run mv "${filename}.new" "${filename}"
            run_ok "New configuration saved for you to edit at ${filename}"
        else
            [ -f "${filename}.new" ] && rm "${filename}.new"
            run_failed "Cannnot download configuration from hibenchmarks daemon using url '${url}'"

            generate_hibenchmarks_conf "${owner}" "${filename}" "${url}"
        fi

        fix_hibenchmarks_conf "${owner}"
    fi
}


# -----------------------------------------------------------------------------
# add hibenchmarks user and group

HIBENCHMARKS_WANTED_GROUPS="docker nginx varnish haproxy adm nsd proxy squid ceph nobody"
HIBENCHMARKS_ADDED_TO_GROUPS=""
add_hibenchmarks_user_and_group() {
    local homedir="${1}" g

    if [ ${UID} -eq 0 ]
        then
        portable_add_group hibenchmarks || return 1
        portable_add_user hibenchmarks "${homedir}"  || return 1

        for g in ${HIBENCHMARKS_WANTED_GROUPS}
        do
            portable_add_user_to_group ${g} hibenchmarks && HIBENCHMARKS_ADDED_TO_GROUPS="${HIBENCHMARKS_ADDED_TO_GROUPS} ${g}"
        done

        [ ~hibenchmarks = / ] && cat <<USERMOD

The hibenchmarks user has its home directory set to /
You may want to change it, using this command:

# usermod -d "${homedir}" hibenchmarks

USERMOD
        return 0
    fi

    return 1
}