# A repository

A GitHub repository is a Git repository with a web page around it.
A public one is read by anyone, with no account.

## In the browser

Go to the [browser](:panel:vnc), which shows [this course's repository](:navigate:github:https://github.com/devpro-training/course-samples).

1. The tabs under the repository name are the features of GitHub around the code: **Code**, **Issues**, **Pull requests**, **Actions**, **Projects**, **Security and quality** and **Insights**.
   A repository owner can hide some of them, so the list can differ from one repository to another.

2. Under the tabs, the **README.md** of the repository is displayed below its files, rendered from Markdown.

3. Click the **main** button above the file list, and the **Branches** and **Tags** tabs of the list show what the repository holds.

4. Click **Commits**, next to the number of commits above the file list, for the history.
   The first one is **Initial commit**.

## With Git

The page and Git show the same repository.

1. In the [terminal](:panel:terminal), clone it:

   <!-- verify: requires=network timeout=120 expect="Cloning into" -->

   ```bash exec
   cd ~/lab && \
   git clone https://github.com/${COURSE_REPO}.git
   ```

2. Look at its history, the one of the **Commits** page:

   <!-- verify: expect="Initial commit" -->

   ```bash exec
   cd ~/lab/course-samples && \
   git log --oneline
   ```

3. List the branches, the ones of the **Branches** tab:

   <!-- verify: expect="remotes/origin/main" -->

   ```bash exec
   cd ~/lab/course-samples && \
   git branch --all
   ```

   > [!NOTE]
   > `main` is the **default branch**: the one cloned, shown first and used as the base of pull requests.
