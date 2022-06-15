B#! /bin/bash
#===========================
# By default, gcc 4.8.5 is 
# installed on Centos7.
# The Intel-OneAPI needs 7.3.1.
# We can use software collections
# to update gcc based on:
# https://linuxize.com/post/how-to-install-gcc-compiler-on-centos-7/
#============================

# (Already installed on node, but here
#  for completeness.  This was done to
#  allow for using Python 3.8 with Centos7,
#  see /opt/rh/rh-python38.)
sudo yum install centos-release-scl

# This adds software to /opt/rh/devtoolset-7:
sudo yum install devtoolset-7

# This is the command that launches a 
# new shell with gcc 7.3.1
# (Run subsequent install steps with this shell.)
scl enable devtoolset-7 bash
