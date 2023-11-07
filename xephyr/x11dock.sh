#! /bin/bash
#
# Xephyrdocker:     Example script to run docker GUI applications in Xephyr.
#
# Usage:
#   Xephyrdocker WINDOWMANAGER DOCKERIMAGE [IMAGECOMMAND [ARGS]]
#
# WINDOWMANAGER     host window manager for use with single GUI applications.
#                   To run without window manager from host, use ":"
# DOCKERIMAGE       docker image containing GUI applications or a desktop
# IMAGECOMMAND      command to run in image
#
Windowmanager="$1" && shift
Dockerimage="$*"

# Container user
Useruid=$(id -u)
Usergid=$(id -g)
Username="$(id -un)"
[ "$Useruid" = "0" ] && Useruid=1000 && Usergid=1000 && Username="user$Useruid"

# Find free display number
for ((Newdisplaynumber=1 ; Newdisplaynumber <= 100 ; Newdisplaynumber++)) ; do
  [ -e /tmp/.X11-unix/X$Newdisplaynumber ] || break
done
Newxsocket=/tmp/.X11-unix/X$Newdisplaynumber

# Cache folder and files
Cachefolder=/tmp/Xephyrdocker_X$Newdisplaynumber
[ -e "$Cachefolder" ] && rm -R "$Cachefolder"
mkdir -p $Cachefolder
Xclientcookie=$Cachefolder/Xcookie.client
Xservercookie=$Cachefolder/Xcookie.server
Xinitrc=$Cachefolder/xinitrc
Etcpasswd=$Cachefolder/passwd

# Command to run docker
# --rm                               Created container will be discarded.
# -e DISPLAY=$Newdisplay             Set environment variable to new display.
# -e XAUTHORITY=/Xcookie             Set environment variable XAUTHORITY to provided cookie.
# -v $Xclientcookie:/Xcookie:ro      Provide cookie file to container.
# -v $NewXsocket:$NewXsocket:ro      Share new X socket of Xephyr.
# --user $Useruid:$Usergid           Security: avoid root in container.
# -v $Etcpasswd:/etc/passwd:ro       Share custom /etc/passwd file with user entry.
# --group-add audio                  Allow ALSA access to /dev/snd if shared with '--device /dev/snd' .
# --cap-drop ALL                     Security: disable needless capabilities.
# --security-opt no-new-privileges   Security: forbid new privileges.
# --init                             Run with init system tini if available.
Dockercommand="docker run --rm \
  -e DISPLAY=:$Newdisplaynumber \
  -e XAUTHORITY=/Xcookie \
  -v $Xclientcookie:/Xcookie:ro \
  -v $Newxsocket:$Newxsocket:rw \
  --user $Useruid:$Usergid \
  -v $Etcpasswd:/etc/passwd:ro \
  --group-add audio \
  --env HOME=/tmp \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  $(command -v docker-init >/dev/null && echo --init) \
  $Dockerimage"

echo "docker command: 
$Dockercommand
"

# Command to run Xorg or Xephyr
#  /usr/bin/Xephyr                An absolute path to X server executable must be given for xinit.
#  :$Newdisplaynumber             First argument has to be new display.
#  -auth $Xservercookie           Path to cookie file for X server.
#  -extension MIT-SHM             Disable MIT-SHM to avoid rendering glitches and bad RAM access.
#  -nolisten tcp                  Disable TCP connections, local access only.
#  -retro                         Nice retro look.
Xcommand="/usr/bin/Xephyr :$Newdisplaynumber \
  -auth $Xservercookie \
  -extension MIT-SHM \
  -nolisten tcp \
  -screen 1000x750x24 \
  -retro"
  
echo "X server command:
$Xcommand
"

# Create /etc/passwd with unprivileged user
echo "root:x:0:0:root:/root:/bin/sh" >$Etcpasswd
echo "$Username:x:$Useruid:$Usergid:$Username,,,:/tmp:/bin/sh" >> $Etcpasswd

# Create xinitrc
{ echo "#! /bin/bash"

  echo "# set environment variables to new display and new cookie"
  echo "export DISPLAY=:$Newdisplaynumber"
  echo "export XAUTHORITY=$Xclientcookie"

  echo "# same keyboard layout as on host"
  echo "echo '$(setxkbmap -display $DISPLAY -print)' | xkbcomp - :$Newdisplaynumber"

  echo "# create new XAUTHORITY cookie file" 
  echo ":> $Xclientcookie"
  echo "xauth add :$Newdisplaynumber . $(mcookie)"
  echo "# create prepared cookie with localhost identification disabled by ffff,"
  echo "# needed if X socket is shared instead connecting over tcp. ffff means 'familiy wild'"
  echo 'Cookie=$(xauth nlist '":$Newdisplaynumber | sed -e 's/^..../ffff/')" 
  echo 'echo $Cookie | xauth -f '$Xclientcookie' nmerge -'
  echo "cp $Xclientcookie $Xservercookie"
  echo "chmod 644 $Xclientcookie"

  echo "# run window manager in Xephyr"
  echo $Windowmanager' & Windowmanagerpid=$!'

  echo "# show docker log"
  echo 'tail --retry -n +1 -F '$Dockerlogfile' 2>/dev/null & Tailpid=$!'

  echo "# run docker"
  echo "$Dockercommand"
} > $Xinitrc

xinit  $Xinitrc -- $Xcommand
rm -Rf $Cachefolder