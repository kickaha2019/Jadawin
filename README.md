# Jadawin

*Jadawin* is a DSL for simple static website 
generation, together with a Ruby 
implementation. It is not a general purpose
tool, for that consider
[Hugo](https://gohugo.io) or
[Jekyll](https://jekyllrb.com) or many others.

The documentation is online at
[documentation](https://alofmethbin.com/Jadawin).
It can be generated from the source files in
the **docs** folder by running something like the
following commands in a Bash shell:

```
gem install bundler ruby-vips liquid
BUNDLE_GEMFILE=ruby/Gemfile;export BUNDLE_GEMFILE
mkdir html
bundle exec ruby ruby/Compiler.rb docs config.yaml html
```

when positioned at the top-level of a clone
of this repo. This
will generate HTML files into a *html*
folder.