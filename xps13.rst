=====
xps13
=====

.. contents:: Table of Contents
.. section-numbering::

Description
===========

Notes specific to Arch XPS13 setup...

Spotify
=======

Scaling is awful. Add this to /usr/share/applications/spotify.desktop ::

    # original
    Exec=spotify %U
    # modified
    Exec=spotify --force-device-scale-factor=2 %U

