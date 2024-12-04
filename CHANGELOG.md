# CHANGELOG

### Unreleased
- [View Diff](https://github.com/westonganger/rails_local_analytics/compare/v0.1.0...master)
- [#8](https://github.com/westonganger/rails_local_analytics/pull/8) - Improve performance significantly using SQL GROUP_BY and pagination of 1000 per page, app tested using seed of 100,000 records
- [#7](https://github.com/westonganger/rails_local_analytics/pull/7) - Create separate tabs for page/site analytics, improve routes, fix multi_search, add more time quicklinks
- [#6](https://github.com/westonganger/rails_local_analytics/pull/6) - Inline javascript file
- [#5](https://github.com/westonganger/rails_local_analytics/pull/5) - Show page analytics on dashboard by default instead of site analytics
- [#4](https://github.com/westonganger/rails_local_analytics/pull/4) - Make search form auto-submit upon changing any fields
- [#3](https://github.com/westonganger/rails_local_analytics/pull/3) - Use `sanitize_sql_like` and `AND` in `multi_search` scope
- [#2](https://github.com/westonganger/rails_local_analytics/pull/2) - Do not downcase URLs
- [#1](https://github.com/westonganger/rails_local_analytics/pull/1) - Backport `Browser#chromium_based?` when `browser` gem version is 5.x or below.

### v0.1.0 - Dec 3 2024
- Initial gem release
