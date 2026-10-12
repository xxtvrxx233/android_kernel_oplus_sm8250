# Build it yourself?

Build Kernel
```bash
  sh ./build.sh
```
Build Kernel with BakaSU
```bash
  sh ./build_ksu.sh
```


# Kernel CI Build System
This repository is equipped with a fully automated kernel build system powered by GitHub Actions.
Once code is pushed to the repository, the kernel will be built and packaged automatically in the cloud, eliminating the need for local builds

You can download artifacts [here](https://github.com/xxtvrxx233/android_kernel_oplus_sm8250/actions)


___________________________________________________________________________________________________

Linux kernel
============

There are several guides for kernel developers and users. These guides can
be rendered in a number of formats, like HTML and PDF. Please read
Documentation/admin-guide/README.rst first.

In order to build the documentation, use ``make htmldocs`` or
``make pdfdocs``.  The formatted documentation can also be read online at:

    https://www.kernel.org/doc/html/latest/

There are various text files in the Documentation/ subdirectory,
several of them using the Restructured Text markup notation.
See Documentation/00-INDEX for a list of what is contained in each file.

Please read the Documentation/process/changes.rst file, as it contains the
requirements for building and running the kernel, and information about
the problems which may result by upgrading your kernel.

