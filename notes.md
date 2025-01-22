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
  - `https://ftp.rtems.org/pub/rtems/releases/6/rc/6.1-rc2/sources/gcc-13.3.0.tar.xz`
- Which ends up in
  - `sources/gcc-13.3.0.tar.xz`

It looks like we need to add something like this:
```
%patch add gcc file:///local_patch/gcc.patch
%hash sha256 gcc.patch 9c2b548cf4c2b4dd202993b221afef14bd1ce9b799b2209755507190648fdffe
```
to `rtems-gcc-13.3-newlib-head.cfg` in order to patch the gcc build.

Note the value of %{rtems_gcc_pathces} gets set here:
- `rtems/config/rtems-urls.bset`

See https://docs.rtems.org/branches/master/user/rsb/project-sets.html#patches.

## working out what needs patching

The above tar file is expanded into
- `rtems/build/powerpc-rtems6-gcc-13.2.0-newlib-3cacedb-x86_64-linux-gnu-1`

So just need to look through that and work out a patch! :-O

## UPDATE Jan 2024

So what needs patching is defined in local_patch/gcc.patch.
BUT NOTE: this essentially overriding the two Make MACROS:-
- MULTILIB_OPTIONS
- MULTILIB_DIRNAMES

Surely it would be better to work out how to pass overrides for these to the
make command line.

---

# Notes on attempts to change compiler options

https://docs.rtems.org/docs/4.11.0/rsb

To run the source builder manually (NOT IN TMP! due to executable permissions):
```bash
curl -O https://ftp.rtems.org/pub/rtems/releases/6/6.1/sources/rtems-source-builder-6.1.tar.xz
tar -xJf rtems-source-builder-6.1.tar.xz
cd rtems-source-builder-6.1/rtems
# Note that the 6 directory is found in rtems-source-builder-6.1/rtems/config
# Note that no-clean allows us to make changes and test re-running the build quickly
../source-builder/sb-set-builder --prefix=../rtems-build 6/rtems-powerpc.bset --no-clean
```


../source-builder/sb-set-builder can be passed --dry-run and other args
see [debugging](https://docs.rtems.org/docs/4.11.0/rsb/configuration.html#debugging).
Also note that the log file appears in cwd as
```
rsb-log-202xxxxx-xxxxx.txt
```