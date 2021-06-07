Fermo uses EEx and Slime to convert HTML templates into HTML.
Assests are handled via a Webpack pipeline.

In 'live' mode, it runs Webpack in live mode alongside an internal web server
that builds pages on the fly (see Fermo.Live.Server).

Live mode can be integrated with various change-listener mechanisms,
so that changes cause pages to be reloaded (see Fermo.Live.Dependencies).
