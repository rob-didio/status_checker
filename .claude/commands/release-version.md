Create a new release for StatusChecker.

Steps:
1. Run `git tag -l 'v*' --sort=-v:refname | head -5` to check existing tags and determine the next version
2. Ask the user what version to release (suggest the next logical version based on existing tags, or v0.1.0 if no tags exist)
3. Verify there are no uncommitted changes with `git status`
4. Create the git tag: `git tag v<version>`
5. Push the tag: `git push origin v<version>`
6. Tell the user the tag has been pushed and that the GitHub Actions release pipeline will build and publish the release
7. Provide the link: https://github.com/rob-didio/status_checker/actions to monitor the build
