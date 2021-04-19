======
XPS 13
======

.. contents:: Table of Contents
.. section-numbering::

Description
===========

Notes specific to Arch XPS13 setup...

`Offical Arch XPS-13 Wiki <https://wiki.archlinux.org/index.php/Dell_XPS_13_(9370)>`_

Spotify
=======

Scaling is awful. Add this to /usr/share/applications/spotify.desktop ::

    # original
    Exec=spotify %U
    # modified
    Exec=spotify --force-device-scale-factor=2 %U

i3lock
======

Add /etc/systemd/system/i3lock.service ::

    # file /etc/systemd/system/i3lock.service
    [Unit]
    Description=Lock the screen on resume from suspend

    [Service]
    User=jgutel
    Type=forking
    Environment=DISPLAY=:0
    ExecStart=/usr/bin/i3lock -b -i /home/jgutel/Pictures/lockscreen.png -e -f

    [Install]
    WantedBy=sleep.target suspend.target

rEFInd-Theme
============

Added as a submodule.

``git submodule update --init --recursive``

https://github.com/gutelfuldead/rEFInd-Theme
