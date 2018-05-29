
MeenyLaTeX
=========

MeenyLaTeX is an experimental version of the MiniLatex
package.


MiniLatex (the language) is a subset of LaTeX that can be rendered
into pdf by standard tools such as `pdflatex`.  MiniLatex source
text can be live-rendered in a web browser using a suitable application, e.g.,
[MiniLatex Demo](https://jxxcarlson.github.io/app/minilatex/src/index.html)
or [www.knode.io](http://www.knode.io)  For a technical discussion,
see the Hackernoon article, [Towards LaTeX in the Browser](https://hackernoon.com/towards-latex-in-the-browser-2ff4d94a0c08).

You can experiment with the old MiniLaTeX using this
[Ellie](https://ellie-app.com/jNN8tyQdh2a1)  I will have an
Ellie version of MeenyLatex up soon.  For now, the best way
to test this package is by running the demo app in `./demo`.
Better docs soon!

*Changes:* (1) MeenyLatex renders LaTeX source text into `Html a` rather than
`String` representing Html.  (2) The
`Driver` module uses the `Html a` renderer as does the demo app.  (3)
MathJax is called to render formulas using custom elements (courtesy of @luke),
rather than using ports.

I plan to re-expose a `Driver` module which uses the `String` renderer.
This is needed for printing.

Note:  Since this is the experimental version,
the API may change (and be cleaned up) substantially.  
I've exposed much more than
is eventually needed in order to experiment better.



Note to myself
--------------
On my laptop, this repository is in /Users/carlson/dev/apps/MeenyLatex


Acknowledgments
---------------  

I wish to acknowledge the generous help that I have received throughout this project from the community at http://elmlang.slack.com, with special thanks to Ilias van Peer (@ilias), Luke Westby (@luke), and
Evan Czaplicki (@evancz).
