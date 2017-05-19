My config files
===============

Install via [ansible](http://docs.ansible.com/ansible/) with the following
command, which will prompt for sudo password (pacman package installation) due
to the `-K` or `--ask-become-pass` flag:

```bash
 ansible-playbook main.yml -i hosts -K
```

Tags
----

Ansible allows you to run specific parts of a playbook by using `--tags
"<tag1>,<tag2>,...". I have the following tags:

* `repos`: Just do the git clones of my repos.

Notes
-----

* Hard-coded to ArchLinux and my own needs.
* Need to out-of-band sort out ssh keys for grabbing github repos.

Ansible Gotchas
---------------

Since I'm doing this to both:

* Bring up new dev environments more quickly.
* Learn ansible.

This section will have a brain-dump of stuff that is important to me at the
time of learning. Expect this to contain trivial or garbage knowledge if you
know a better way.

* [Get ansible variables](http://stackoverflow.com/questions/18839509/where-can-i-get-a-list-of-ansible-pre-defined-variables):
  `ansible -m setup 127.0.0.1`.
