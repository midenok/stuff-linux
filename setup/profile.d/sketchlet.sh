if [ -x /usr/bin/dot ]; then
    export GRAPHVIZ_DOT=/usr/bin/dot
fi

if [ -f /opt/sketchlet/bin/sketchlet.jar ]; then
    export SKETCHLET_HOME=/opt/sketchlet
    sketchlet()
    {
        java -Xms100m -Xmx800m -jar $SKETCHLET_HOME/bin/sketchlet.jar
    }
    export -f sketchlet
fi
