## Azure CLI

The [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) is a Python program, `az`, that calls Azure Resource Manager.
Microsoft recommends the package manager of the distribution on Linux, which needs root.
The lab runs without it, so the package is installed with pip in a virtual environment of the home directory.

The Debian of the lab image carries Python but not pip, and refuses a `pip install` outside a virtual environment.
pip is therefore taken from its wheel, checked against the checksum of the package index, and used to fill the virtual environment.

1. Download the wheel of pip and check it:

   <!-- verify: requires=network timeout=120 expect="pip-26.2.1-py3-none-any.whl: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "${PIP_WHEEL_URL}" && \
   echo "${PIP_WHEEL_SHA256}  pip-${PIP_VERSION}-py3-none-any.whl" | sha256sum --check
   ```

2. Create the virtual environment without pip, and install `azure-cli` into it, at the pinned version.
   The package brings its dependencies, about 700 MB in all, so it takes a minute:

   <!-- verify: requires=network timeout=600 expect="Successfully installed" -->

   ```bash exec
   cd ~ && \
   python3 -m venv --without-pip ~/.azure-venv && \
   python3 "pip-${PIP_VERSION}-py3-none-any.whl/pip" --python ~/.azure-venv/bin/python install "azure-cli==${AZURE_CLI_VERSION}" && \
   rm "pip-${PIP_VERSION}-py3-none-any.whl"
   ```

3. Add the environment to the `PATH`, now and for every new shell, and check the version:

   <!-- verify: expect="azure-cli-core" -->

   ```bash exec
   export PATH="$HOME/.azure-venv/bin:$PATH" && \
   echo 'export PATH="$HOME/.azure-venv/bin:$PATH"' >> ~/.bashrc && \
   az version
   ```

4. The CLI collects usage data by default.
   Turn it off, a setting kept in `~/.azure/config`:

   <!-- verify: expect="collect_telemetry = false" -->

   ```bash exec
   az config set core.collect_telemetry=false && \
   cat ~/.azure/config
   ```
