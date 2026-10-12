## Ansible

[Ansible](https://docs.ansible.com/projects/ansible/latest/) is a Python program, installed here with pip in a virtual environment of the home directory.
`ansible-core` is the engine, with the modules of `ansible.builtin`.
The `ansible` package of the community adds hundreds of collections on top of it, which this course does not need.

The Debian of the lab image carries Python but not pip, and refuses a `pip install` outside a virtual environment.
pip is therefore taken from its wheel, checked against the checksum of the package index, and used to fill the virtual environment.

1. Download the wheel of pip and check it:

   <!-- verify: requires=network timeout=120 expect="pip-26.2.1-py3-none-any.whl: OK" -->

   ```bash exec
   cd ~ && \
   wget -q "${PIP_WHEEL_URL}" && \
   echo "${PIP_WHEEL_SHA256}  pip-${PIP_VERSION}-py3-none-any.whl" | sha256sum --check
   ```

2. Create the virtual environment without pip, and install `ansible-core` into it, at the pinned version.
   A wheel is a zip file that Python can run, and `--python` points pip at the environment to fill:

   <!-- verify: requires=network timeout=300 expect="Successfully installed" -->

   ```bash exec
   cd ~ && \
   python3 -m venv --without-pip ~/.ansible-venv && \
   python3 "pip-${PIP_VERSION}-py3-none-any.whl/pip" --python ~/.ansible-venv/bin/python install "ansible-core==${ANSIBLE_CORE_VERSION}" && \
   rm "pip-${PIP_VERSION}-py3-none-any.whl"
   ```

3. Add the environment to the `PATH`, now and for every new shell, and check the version:

   <!-- verify: expect="ansible [core 2.19" -->

   ```bash exec
   export PATH="$HOME/.ansible-venv/bin:$PATH" && \
   echo 'export PATH="$HOME/.ansible-venv/bin:$PATH"' >> ~/.bashrc && \
   ansible --version
   ```

   The version is the newest series that the Python 3.11 of the image can run: `ansible-core` 2.20 and 2.21 need Python 3.12 or newer on the control node.
