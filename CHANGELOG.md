# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.1] - 2026-04-07

### Added
- `truncate` built-in filter with optional length argument (defaults to 30)

## [0.5.0] - 2026-04-05

### Added
- Strict mode now raises `UndefinedFilterError` for unknown filters
- `Template.registered_partials` and `Template.registered_layouts` class methods
- Thread-safety note in README

## [0.4.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.4.0] - 2026-03-29

### Added
- Comment syntax (`{{! comment }}`) for stripping comments from rendered output, including multi-line support
- Strict mode (`Template.new(source, strict: true)`) that raises `UndefinedVariableError` for undefined variables
- Whitespace control (`{{~ var }}`, `{{ var ~}}`, `{{~ var ~}}`) for trimming spaces and tabs around tags

## [0.3.0] - 2026-03-28

### Added
- Partials/includes support (`{{> partial_name}}`) with `register_partial` and `clear_partials!`
- Custom delimiters (`{{= <% %> =}}`) to change tag delimiters mid-template
- Filter/pipe syntax (`{{name | upcase}}`) with built-in filters: upcase, downcase, strip, escape, capitalize, reverse, length, default
- Custom filter registration via `Filters.register`
- Template compilation and caching via `Template.compile` for repeated renders
- Template inheritance/layouts (`{{< layout}}` with `{{$ block_name}}` block overrides)
- Lambda/Proc support in sections for dynamic content generation

## [0.2.2] - 2026-03-26

### Changed
- Add Sponsor badge to README
- Fix License section format
- Sync gemspec summary with README


## [0.2.1] - 2026-03-24

### Fixed
- Align README one-liner with gemspec summary

## [0.2.0] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.9] - 2026-03-24

### Fixed
- Standardize README API section to table format

## [0.1.8] - 2026-03-23

### Fixed
- Standardize README/CHANGELOG to match template guide

## [0.1.7] - 2026-03-22

### Changed
- Expand test coverage

## [0.1.6] - 2026-03-20

### Fixed
- Standardize Installation section in README
- Fix README description trailing period
- Fix CHANGELOG header wording

## [0.1.5] - 2026-03-20

### Changed
- Restructure CHANGELOG to follow Keep a Changelog format

## [0.1.4] - 2026-03-18

### Changed
- Revert gemspec to single-quoted strings per RuboCop default configuration

## [0.1.3] - 2026-03-18

### Fixed
- Fix RuboCop Style/StringLiterals violations in gemspec

## [0.1.2] - 2026-03-16

### Added
- Add License badge to README
- Add bug_tracker_uri to gemspec
- Add Requirements section to README

## [0.1.1] - 2026-03-15

### Added
- Add Development section to README

## [0.1.0] - 2026-03-15

### Added
- Initial release
- Mustache-style logic-less templates
- Safe rendering without eval
- Section and inverted section support
- Partial template inclusion
