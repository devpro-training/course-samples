# The project

A pipeline needs something to build.
The sample is a Python module, `hello.py`, with its unit tests, using only the standard library: nothing to install, so the pipeline stays short.

## The code

1. Create the repository, with the files a pipeline produces left out of it:

   <!-- verify: expect="Initialized empty Git repository" -->

   ```bash exec
   mkdir -p ~/lab/hello/ci && \
   cd ~/lab/hello && \
   git init && \
   printf 'dist/\n__pycache__/\n' > .gitignore
   ```

2. Write the module and its tests:

   ```bash exec
   cd ~/lab/hello && \
   cat > hello.py <<'EOT'
   import sys


   def greet(name):
       return f"Hello, {name}!"


   if __name__ == "__main__":
       print(greet(sys.argv[1] if len(sys.argv) > 1 else "world"))
   EOT
   cat > test_hello.py <<'EOT'
   import unittest

   from hello import greet


   class GreetTest(unittest.TestCase):
       def test_greets_by_name(self):
           self.assertEqual(greet("Ada"), "Hello, Ada!")

       def test_greets_with_a_comma(self):
           self.assertIn(", ", greet("Ada"))


   if __name__ == "__main__":
       unittest.main()
   EOT
   ```

   [Open hello.py](:open:hello/hello.py) and [open test_hello.py](:open:hello/test_hello.py).

## Run it

1. Run the application:

   <!-- verify: expect="Hello, Ada!" -->

   ```bash exec
   cd ~/lab/hello && \
   python3 hello.py Ada
   ```

2. Run the tests:

   <!-- verify: expect="Ran 2 tests" -->

   ```bash exec
   cd ~/lab/hello && \
   python3 -m unittest -v
   ```

Both commands work on any machine with Python 3.
A pipeline does nothing more than run commands like these, on a machine that is not the author's.
