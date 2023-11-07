xhost +SI:localuser:$(id -un)
docker run --rm \
            -e DISPLAY=$DISPLAY \
            -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
            --ipc=host \
            --user $(id -u):$(id -g) \
            --cap-drop=ALL \
            --security-opt=no-new-privileges \
            imagename imagecommand 
