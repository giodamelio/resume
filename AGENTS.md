# Repository Guidelines

## Project Structure & Module Organization
- `resume.nix` holds the JSON Resume data and is the single source of truth for contact info, work history, and skills.
- `macchiato/` contains the HTML template, CSS rules, and assets that Nix uses to render the page. Keep layout tweaks and typography changes within `macchiato/src/style.css` so they stay aligned with the current build.
- Build artifacts wind up in `result/`, with `result/index.html` serving as the nightly preview of the HTML output.

## Build, Test, and Development Commands
- `nix build .#resume-html` – regenerate the HTML resume after you edit `resume.nix` or `macchiato/`. Nix caches the template and style assets, so clean runs happen automatically.
- `nix develop` (optional) – drops you into the flake’s dev shell when you need to inspect tools or run ad-hoc commands before rebuilding.
- `nix flake check` – useful for ensuring the flake stays healthy before pushing, even though the default flow centers on the resume build.

## Coding Style & Naming Conventions
- Stick to two-space indentation in both Nix and CSS files to match the existing layout and keep diffs tidy.
- Keep identifiers lowercase and hyphen-delimited in the CSS (`.left-column`, `.pdf-link`) and retain the existing font-family spellings to avoid duplication.
- When editing `resume.nix`, keep keys grouped by sections (`basics`, `work`, `skills`) and rely on the structured format instead of ad-hoc strings.

## Testing Guidelines
- There is no automated test suite; validation consists of running `nix build .#resume-html` and confirming the generated HTML matches expectations.
- Check `result/index.html` in a browser and verify that typography, spacing, and links behave before committing.

## Preview & Validation Notes
- After the build succeeds, open `./result/index.html` to ensure recent edits render correctly. Refresh the file after each iteration and keep an eye on style regressions from `macchiato/src/style.css` or data collapses from `resume.nix`.
