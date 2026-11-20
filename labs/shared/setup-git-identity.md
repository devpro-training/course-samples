## Git identity

1. Set the identity recorded in commits, and `main` as the first branch of new repositories:

   ```bash exec
   git config --global user.name "${GIT_USER_NAME}" && \
   git config --global user.email "${GIT_USER_EMAIL}" && \
   git config --global init.defaultBranch main
   ```
