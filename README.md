# Fermo

# Approach

When a Fermo project is compiles, all pages (single pages, proxy templates
and partials) are located.

Pages which have a special function (e.g. templates and partials) are filtered
out and remaining pages are queued for conversion to HTML.

# Defaults

Fermo was build to mimic the behaviour of Middleman, so it's defaults
tend to be the same its progenitor.

A number of helper methods are provided (e.g. `javascript_include_tag`) to
allow easy porting of Middleman projects.
