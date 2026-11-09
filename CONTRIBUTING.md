# Contributing

Follow the [README setup instructions](README.md#run-locally) to select the
repository's Ruby version and install its locked dependencies.

## Make a focused change

Keep each change small and reviewable: address one issue or closely related
outcome at a time, and avoid unrelated refactors or speculative implementation
details. When opening an issue, describe the desired outcome and acceptance
criteria using the [issue template](.github/ISSUE_TEMPLATE/issue.md).

## Tests and checks

Run the same checks as CI from the repository root:

```sh
RAILS_ENV=test bin/rails db:prepare
bin/rails test
bundle exec rubocop
bin/rails zeitwerk:check
BUNDLE_WITHOUT=development:test RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
BUNDLE_WITHOUT=development:test RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails zeitwerk:check
bin/rails assets:clobber
```

Add or update tests for changed behavior. At minimum, run the focused test(s)
while iterating, then run the checks above before proposing the change. The last
command removes generated assets so they do not shadow local CSS or JavaScript
changes. Run it even if a production check fails. The dummy secret is for
build-time checks only; do not use it to run a deployed application.

Tests use a separate SQLite database and need no external database service.
Rubocop uses the standard Rails Omakase rules in `.rubocop.yml`.
Production checks exclude development and test gems, compile the assets, and
verify that the application eager-loads. There is no container build check yet:
the repository does not have a Dockerfile or deployment configuration.

## Pull requests

Describe the behavior changed, link the relevant issue, and explain how you
checked the change. GitHub Actions runs **Application tests**, **Code quality**,
and **Production build** on every pull request and on pushes to `main`. Each
check has its own status and failing command output in the Actions log; failing
test runs also upload the test log for seven days. Do not include secrets or
personal data in test fixtures or logs.

For user-facing visual changes, attach visual evidence to the pull request
description: before/after screenshots for both a narrow phone viewport (for
example 390px wide) and a desktop viewport. Label the viewport sizes and show
relevant states, including errors or empty states when changed. For a new
screen, an after screenshot is sufficient. Also check keyboard navigation and
visible focus; screenshots do not replace those checks. For changes that do not
affect the UI, screenshots are not needed.

All three checks should pass before merging. Requiring them through a branch
protection rule or ruleset is a repository-owner setting, not something the
workflow itself enforces.
