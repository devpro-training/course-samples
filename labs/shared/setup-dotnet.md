## .NET SDK

The lab runs as a user with no administrator rights, so the SDK is installed in the home directory with the official `dotnet-install.sh` script.

> [!NOTE]
> Microsoft recommends the script for automation and non-admin installs, and the installers or the package managers for a development machine.
> Those need administrator rights, which the lab does not have.

1. Download the script, its signature and the public key it is signed with, then verify it:

   <!-- verify: requires=network timeout=120 expect="Good signature from" -->

   ```bash exec
   cd ~ && \
   wget -q "${DOTNET_INSTALL_URL}/dotnet-install.sh" "${DOTNET_INSTALL_URL}/dotnet-install.sig" "${DOTNET_INSTALL_URL}/dotnet-install.asc" && \
   gpg --import dotnet-install.asc && \
   gpg --verify dotnet-install.sig dotnet-install.sh
   ```

   > [!NOTE]
   > `gpg` warns that the key is not certified: it only says the key is not in a trusted keyring.
   > `Good signature` is the result that matters.

2. Run the script for the SDK version of this course, then delete the downloaded files:

   <!-- verify: requires=network timeout=300 expect="Installation finished successfully" -->

   ```bash exec
   chmod +x dotnet-install.sh && \
   ./dotnet-install.sh --version "${DOTNET_SDK_VERSION}" --install-dir ~/.dotnet && \
   rm dotnet-install.sh dotnet-install.sig dotnet-install.asc
   ```

3. The script does not set `DOTNET_ROOT`, and does not change the `PATH` of new shells.
   Set them, with two options that keep the output short, now and for every new shell:

   ```bash exec
   export DOTNET_ROOT="$HOME/.dotnet" && \
   export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools" && \
   export DOTNET_NOLOGO=1 && \
   export DOTNET_CLI_TELEMETRY_OPTOUT=1 && \
   echo 'export DOTNET_ROOT="$HOME/.dotnet"' >> ~/.bashrc && \
   echo 'export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"' >> ~/.bashrc && \
   echo 'export DOTNET_NOLOGO=1' >> ~/.bashrc && \
   echo 'export DOTNET_CLI_TELEMETRY_OPTOUT=1' >> ~/.bashrc
   ```

   > [!NOTE]
   > `DOTNET_NOLOGO` hides the welcome banner of the first run.
   > `DOTNET_CLI_TELEMETRY_OPTOUT` stops the SDK from sending usage data to Microsoft, which it does by default.

4. List what is installed: the SDK, and the runtimes it carries.

   <!-- verify: expect="Microsoft.NETCore.App 10." -->

   ```bash exec
   dotnet --list-sdks && dotnet --list-runtimes
   ```

5. The script does not install the libraries .NET needs from the system.
   The Debian 12 list is in Microsoft's documentation, and the lab image carries it:

   <!-- verify: expect="72.1-3" -->

   ```bash exec
   dpkg-query -W -f '${Package} ${Version}\n' ca-certificates libc6 libgcc-s1 libgssapi-krb5-2 libicu72 libssl3 libstdc++6 tzdata
   ```

   > [!NOTE]
   > On Linux, a .NET app does not start without ICU, the `libicu` package.
   > Without administrator rights, the documented way out is the invariant globalization mode,
   > with `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`, or `<InvariantGlobalization>true</InvariantGlobalization>` in the project, at the price of culture data.
   > With them, install the `libicu` package of the distribution.
