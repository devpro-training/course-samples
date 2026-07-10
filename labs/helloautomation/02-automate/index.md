# Scripted actions and checks

[Switch to browser](:panel:vnc)

These links are defined in `automation.yaml` at the course root and run entirely server-side — watch the browser panel as each one runs.

[▶ Log in as admin](:action:login.as-admin)

[▶ Create a demo user](:action:users.create-demo)

[✓ Verify the demo user exists](:action:users.demo-exists)

Try clicking "Verify" before "Create a demo user" — it fails with an inline hint message, rendered from the check's `hint:` field in `automation.yaml`.
