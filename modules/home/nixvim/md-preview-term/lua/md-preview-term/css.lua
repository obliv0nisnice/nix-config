-- Compact GitHub-flavored markdown CSS (light theme), self-contained so the
-- preview works fully offline. Scoped loosely to the document body.
return [[
@page { size: 20cm 300cm; margin: 1.4cm 1.6cm; }
* { box-sizing: border-box; }
body {
  font-family: -apple-system, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif;
  font-size: 11pt;
  line-height: 1.6;
  color: #1f2328;
  word-wrap: break-word;
}
a { color: #0969da; text-decoration: none; }
strong { font-weight: 600; }

h1, h2, h3, h4, h5, h6 { font-weight: 600; line-height: 1.25; margin: 24px 0 16px; }
h1 { font-size: 2em; padding-bottom: .3em; border-bottom: 1px solid #d1d9e0; }
h2 { font-size: 1.5em; padding-bottom: .3em; border-bottom: 1px solid #d1d9e0; }
h3 { font-size: 1.25em; }
h4 { font-size: 1em; }
h5 { font-size: .875em; }
h6 { font-size: .85em; color: #59636e; }
p { margin: 0 0 16px; }

ul, ol { margin: 0 0 16px; padding-left: 2em; }
li { margin-top: .25em; }
li > p { margin-top: 16px; }
ul.task-list { list-style: none; padding-left: 1.2em; }
ul.task-list li { position: relative; }
input[type=checkbox] { margin-right: .4em; }

code {
  font-family: ui-monospace, "SFMono-Regular", "JetBrains Mono", Consolas, monospace;
  font-size: 85%;
  background: #818b981f;
  padding: .2em .4em;
  border-radius: 6px;
}
pre {
  background: #f6f8fa;
  padding: 16px;
  border-radius: 6px;
  overflow: auto;
  line-height: 1.45;
  margin: 0 0 16px;
}
pre code { background: transparent; padding: 0; font-size: 85%; }

blockquote {
  margin: 0 0 16px;
  padding: 0 1em;
  color: #59636e;
  border-left: .25em solid #d1d9e0;
}

hr { height: .25em; border: 0; background: #d1d9e0; margin: 24px 0; }

table {
  border-collapse: collapse;
  width: 100%;
  table-layout: fixed;
  margin: 0 0 16px;
}
th, td {
  border: 1px solid #d1d9e0;
  padding: 6px 13px;
  word-wrap: break-word;
  overflow-wrap: anywhere;
  vertical-align: top;
}
th { font-weight: 600; background: #f6f8fa; }
tr:nth-child(2n) td { background: #f6f8fa80; }

img { max-width: 100%; }
]]
