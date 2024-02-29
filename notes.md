# Notes on reducing the size of the beatnik BSP

Motivation: keep the containers small.

1. we can strip all of the x86 binaries with strip from binutils
1. we cannot strip the powerpc libraries because this makes final link fail
1. can we strip any powerpc binaries? how do I find them?
1. gcc builds for a range of powerpc variants - getting rid of all but m7400 will be a massive help.

## patching gcc build in the RS

- the bset file that refers to which gcc gets built is
  - `rtems/config/6/rtems-default.bset`(default tools built for rtems)
  - from
  - `rtems/config/6/rtems-powerpc.bset` (settings for ppc arch)
- The gcc config for this is
  - `rtems/config/tools/rtems-gcc-13.2-newlib-head.cfg`
- The tar file it gets is
  - `https://ftp.rtems.org/pub/rtems/releases/6/rc/6.1-rc2/sources/gcc-13.2.0.tar.xz`
- Which ends up in
  - `sources/gcc-13.2.0.tar.xz`

It looks like we need to add something like this:
```
%patch add gcc %{rtems_gcc_patches}/gcc-core-4.4.7-rtems4.10-20120314.diff
%hash md5 gcc-core-4.4.7-rtems4.10-20120314.diff 084c9085c255b1f6a9204e239dde0579
```
to `rtems-gcc-13.2-newlib-head.cfg` in order to patch the gcc build.

Note the value of %{rtems_gcc_pathces} gets set here:
- `rtems/config/rtems-urls.bset`

See https://docs.rtems.org/branches/master/user/rsb/project-sets.html#patches.

## working out what needs patching

The above tar file is expanded into
- `rtems/build/powerpc-rtems6-gcc-13.2.0-newlib-3cacedb-x86_64-linux-gnu-1`

So just need to look through that and work out a patch! :-O
