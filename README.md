# firestorm-debian

A docker build environment for firestorm.

This builds:

1. a debian 9 stretch container with the firestorm dependencies
2. makes firestorm build from the head of phoenix-firestorm-lgpl

# Compiler Warnings

no attribute 'setbinary'
------------------------
Version skew possibly wrt mercurial:
```
Configuring linux...
-- Using PKG_CONFIG_LIBDIR=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:/usr/local/share/pkgconfig
Traceback (most recent call last):
  File "/usr/bin/hg", line 43, in <module>
    mercurial.util.setbinary(fp)
  File "/usr/local/lib/python2.7/dist-packages/hgdemandimport/demandimportpy2.py", line 151, in __getattr__
    return getattr(self._module, attr)
AttributeError: 'module' object has no attribute 'setbinary'
```
