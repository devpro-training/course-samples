# Text and pipes

Configuration, logs and output are text, and a few commands read, search and count it.
A **pipe** (`|`) sends the output of a command to the input of the next, and `>` sends it to a file.

## A log

1. Write a small web server log, and show it:

   <!-- verify: expect="8 access.log" -->

   ```bash exec target=linux
   mkdir -p ~/lab/text && \
   cd ~/lab/text && \
   tee access.log <<'EOT'
   10.0.0.1 GET /index.html 200
   10.0.0.2 GET /missing 404
   10.0.0.1 GET /about.html 200
   10.0.0.3 POST /login 302
   10.0.0.2 GET /index.html 200
   10.0.0.1 GET /missing 404
   10.0.0.4 GET /index.html 200
   10.0.0.3 GET /admin 403
   EOT
   wc -l access.log
   ```

## Read

1. Show the first two lines and the last one:

   <!-- verify: expect="10.0.0.2 GET /missing 404" -->

   ```bash exec target=linux
   cd ~/lab/text && \
   head -n 2 access.log && \
   tail -n 1 access.log
   ```

## Search

1. `grep` prints the lines that match a text, and `-c` counts them:

   <!-- verify: expect="/missing 404" -->

   ```bash exec target=linux
   cd ~/lab/text && \
   grep ' 404$' access.log && \
   grep -c ' 200$' access.log
   ```

2. `find` searches names, and `grep -r` the content of the files below a folder.
   `2>/dev/null` throws away the errors, such as the folders that cannot be read:

   <!-- verify: expect="/etc/os-release" -->

   ```bash exec target=linux
   find /etc -maxdepth 1 -name 'os-*' 2>/dev/null && \
   grep -rl 'bookworm' /etc/apt/sources.list.d
   ```

## Pipes and files

1. Which address made the most requests: cut the first column, sort it, count the duplicates, and sort the counts:

   <!-- verify: expect="3 10.0.0.1" -->

   ```bash exec target=linux
   cd ~/lab/text && \
   cut -d' ' -f1 access.log | sort | uniq -c | sort -rn
   ```

2. Save the errors in a file with `>`, add a line with `>>`, and count them:

   <!-- verify: expect="4 errors.txt" -->

   ```bash exec target=linux
   cd ~/lab/text && \
   grep -E ' (404|403)$' access.log > errors.txt && \
   echo "checked on $(date +%F)" >> errors.txt && \
   wc -l errors.txt
   ```

Operator | Does
---------|----------------------------------------------
`> f`    | Writes the output to `f`, replacing it
`>> f`   | Appends the output to `f`
`2> f`   | Writes the errors to `f`
`&&`     | Runs the next command only if this one succeeded
