if [ -f ~/.bashrc ] && grep -q 'PS1.*=.*\\w' ~/.bashrc
then
    sed -i -e '/PS1.*=/ {s/\\w/\\W/}' ~/.bashrc
fi
