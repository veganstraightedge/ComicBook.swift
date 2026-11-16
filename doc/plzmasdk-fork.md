# The PLzmaSDK fork

ComicBook.swift reads and writes `.cb7` with [PLzmaSDK](https://github.com/OlehKulykov/PLzmaSDK). It
depends on our fork, [veganstraightedge/PLzmaSDK](https://github.com/veganstraightedge/PLzmaSDK),
not on upstream. This page says why, and how to bring the fork up to date.

## Why the fork exists

Upstream's `Package.swift` sets `unsafeFlags` (`-fPIC`, `-fno-rtti`) on two targets. Swift Package
Manager refuses to use a package with unsafe flags when it is depended on by version, so upstream
can only be pinned by revision, and a revision pin in ComicBook.swift would in turn stop apps from
depending on ComicBook.swift by version.

The fork is upstream plus exactly one commit, "Drop unsafeFlags so the package is consumable by
version". It only touches `Package.swift`. The flags were optimization-only.

An upstream request to remove the flags
([OlehKulykov/PLzmaSDK#7](https://github.com/OlehKulykov/PLzmaSDK/issues/7)) was closed in 2021
with no comment. If upstream ever drops them, retire the fork and depend on upstream directly.

## Versions

| Fork tag | Built on upstream | Upstream build number |
|---|---|---:|
| `1.6.2` | `master` just after upstream's 1.6.1 | 1448 |
| `1.6.3` | `master` just after upstream's 1.6.2 | 1466 |

The fork's numbers do not match upstream's: our `1.6.2` is older code than upstream's `1.6.2`.
Treat the fork's tags as their own sequence.

## Rules that are easy to get wrong

- **Never move or delete a fork tag.** `Package.resolved` in ComicBook.swift, and in every app using
  it, records the tag's commit. Moving a tag breaks their resolution.
- **A new sync needs a new tag.** Use the next free three-part number.
- **Tags must be exactly three numbers.** Tested with Swift 6.4: a `1.6.2.1` tag is silently ignored,
  and asking for it fails with "Invalid semantic version string".
- **Do not use a `+suffix`.** A `1.6.2+fork.1` tag is treated as plain `1.6.2`; with both tags
  present, Swift Package Manager reported "resolved at 1.6.2" and checked out the `+fork.1` commit.
- **Check upstream's tags before picking a number**, so ours does not land on one upstream already
  uses. It may still collide with one upstream releases later; that is the cost of the fork.
- **Upstream rewrites history.** Its `1.6.0` and `1.6.1` tags point at commits that are not on its
  `master`. Always rebuild the fork from `upstream/master`, never by merging old fork history.

## Syncing the fork with upstream

Work in a clone of the fork with two remotes: `origin` (the fork) and `upstream`
(`OlehKulykov/PLzmaSDK`). Paths below assume the clone sits next to ComicBook.swift at
`../vendor/PLzmaSDK`.

1. Fetch both remotes.

   ```sh
   git fetch upstream
   git fetch origin
   ```

2. Check whether the fork is still needed. If this prints nothing, upstream has dropped the flags:
   stop here, point ComicBook.swift's `Package.swift` at upstream, and retire the fork.

   ```sh
   git show upstream/master:Package.swift | grep unsafeFlags
   ```

3. Rebuild our one commit on top of upstream's tip.

   ```sh
   git switch -c integrate-upstream upstream/master
   git cherry-pick origin/master
   ```

   Expect a conflict in `Package.swift`, because upstream changes `LIBPLZMA_VERSION_BUILD` on the
   same lines. Resolve it by keeping upstream's build number and leaving every `.unsafeFlags(...)`
   line out, then `git add Package.swift` and `git cherry-pick --continue`. The result must differ
   from `upstream/master` in `Package.swift` only:

   ```sh
   git diff --stat upstream/master
   ```

4. Test the fork on its own.

   ```sh
   swift build
   swift test
   ```

5. Test ComicBook.swift against the local fork, then undo the override. Run these in
   ComicBook.swift. While the override is active, `swift package show-dependencies` shows PLzmaSDK
   at `@unspecified`.

   ```sh
   swift package edit PLzmaSDK --path ../vendor/PLzmaSDK
   script/test
   swift package unedit PLzmaSDK
   git restore Package.resolved
   ```

6. Publish the rebuilt branch as the fork's `master`. This rewrites the fork's default branch, so
   it is a force-push; the lease makes it fail unless the fork's `master` is still the commit you
   started from. Back in the fork clone:

   ```sh
   git branch -f master integrate-upstream
   git push --force-with-lease=master:<old fork master commit> origin master
   git switch master
   git branch -D integrate-upstream
   ```

   The previous fork commit stays reachable through its tag, so existing pins keep working.

7. Tag the new `master` with the next free number and push the tag.

   ```sh
   git ls-remote --tags upstream
   git tag <next version> master
   git push origin <next version>
   ```

8. Pick it up in ComicBook.swift: raise the `from:` version for PLzmaSDK in `Package.swift`, then

   ```sh
   swift package update PLzmaSDK
   script/test
   script/lint
   ```

   Add a CHANGELOG entry, add a row to the Versions table above, and open a pull request.

Steps 6 and 7 have to be run by a person. Claude Code's auto mode blocks both the force-push and the
tag push to the fork.
