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

