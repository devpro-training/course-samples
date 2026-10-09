# Users and groups

Every process runs as a user, and every file belongs to a user and a group.
The kernel compares them with the permissions of the file to allow or refuse an access.

## Accounts

1. The shell of this lab belongs to `root`, the user number 0, which the kernel never refuses anything:

   <!-- verify: expect="uid=0(root)" -->

   ```bash exec target=linux
   id
   ```

2. Create a group, and a user in it.
   `adduser` creates the account and its home directory, `usermod -aG` adds the user to a group, and `chpasswd` sets its password:

   <!-- verify: expect="(devs)" -->

   ```bash exec target=linux
   groupadd "${LINUX_GROUP}" && \
   adduser --disabled-password --gecos "" "${LINUX_USER}" && \
   usermod -aG "${LINUX_GROUP}" "${LINUX_USER}" && \
   echo "${LINUX_USER}:${LINUX_PASSWORD}" | chpasswd && \
   id "${LINUX_USER}"
   ```

3. The accounts are lines of text files.
   Each line of `/etc/passwd` holds the name, the user number, the group number, the home directory and the shell, and `/etc/group` lists the members of each group:

   <!-- verify: expect="/home/alice:/bin/bash" -->

   ```bash exec target=linux
   getent passwd root "${LINUX_USER}" && \
   getent group "${LINUX_GROUP}"
   ```

   > [!NOTE]
   > The password hashes are in `/etc/shadow`, which only `root` reads.

## Permissions

1. Create a file for the group, readable by its members only.
   The first column of `ls -l` is the type, then three triplets for the **owner**, the **group** and **others**:

   <!-- verify: expect="-rw-r----- 1 root devs" -->

   ```bash exec target=linux
   mkdir -p /srv/project && \
   cd /srv/project && \
   echo "notes of the team" > notes.txt && \
   chown root:"${LINUX_GROUP}" notes.txt && \
   chmod 640 notes.txt && \
   ls -l notes.txt
   ```

   Digit | Permission | On a file          | On a folder
   ------|------------|--------------------|---------------------------
   4     | `r`        | Read it            | List its content
   2     | `w`        | Change it          | Create and remove entries
   1     | `x`        | Run it             | Enter it

   `640` is `6` (4+2) for the owner, `4` for the group and `0` for others.

2. Read it as a member of the group, with `runuser`, which runs a command as another user:

   <!-- verify: expect="notes of the team" -->

   ```bash exec target=linux
   runuser -u "${LINUX_USER}" -- cat /srv/project/notes.txt
   ```

3. Remove the permission of the group, and read it again.
   The command is expected to fail:

   <!-- verify: expect="Permission denied" -->

   ```bash exec target=linux
   chmod 600 /srv/project/notes.txt && \
   { runuser -u "${LINUX_USER}" -- cat /srv/project/notes.txt || true; }
   ```

4. A user does not read the password hashes either:

   <!-- verify: expect="Permission denied" -->

   ```bash exec target=linux
   ls -l /etc/shadow && \
   { runuser -u "${LINUX_USER}" -- cat /etc/shadow || true; }
   ```
