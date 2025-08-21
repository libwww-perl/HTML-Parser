# HTML::Parser - Perl HTML Parser Module

HTML::Parser is a C/XS-based Perl module for parsing HTML documents. It's part of the libwww-perl organization and provides event-driven HTML parsing with support for multiple parser modes and extensive customization options.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

- Bootstrap, build, and test the repository:
  - `perl Makefile.PL` -- generates Makefile (takes ~0.12 seconds)
  - `make` -- builds the C/XS module (takes ~1.5 seconds, NEVER CANCEL)
  - `make test` -- runs 464 tests (takes ~3 seconds, NEVER CANCEL)
- Clean the build:
  - `make clean` -- removes build artifacts (takes ~0.01 seconds)
- Dependencies are automatically handled by the Perl build system:
  - Runtime dependencies: HTML::Tagset, HTTP::Headers, URI, etc.
  - Test dependencies: Test::More, File::Spec, Config, etc.
  - All dependencies are typically available in standard Perl installations

## Validation

- ALWAYS test core functionality after making changes to the XS code or main Parser.pm:
  ```perl
  perl -MHTML::Parser -e 'print "HTML::Parser loads successfully\n"'
  ```
- ALWAYS test example scripts in eg/ directory:
  - `perl eg/htext test.html` -- extracts plain text from HTML
  - `perl eg/hstrip test.html` -- strips unwanted tags and attributes
- ALWAYS run a complete parsing scenario manually:
  - Create test HTML file with various elements (tags, attributes, text, comments)
  - Parse it with HTML::Parser using start_h, end_h, text_h handlers
  - Verify all elements are parsed correctly
- ALWAYS run the full test suite before committing: `make test`
- The test suite covers 464 test cases across 50 test files and must ALL pass

## Build System Details

- Uses ExtUtils::MakeMaker build system (traditional Perl approach)
- XS (C extension) compilation is handled automatically
- Generated files during build: Parser.c (from Parser.xs), Parser.so, blib/ directory
- Configuration: Makefile.PL defines build parameters including MARKED_SECTION support
- Build artifacts are placed in blib/ directory structure

## Project Structure

### Key Files and Directories:
- `lib/HTML/Parser.pm` -- Main Perl module with XS loading
- `Parser.xs` -- XS interface between Perl and C code
- `hparser.c` -- Core C parsing engine
- `lib/HTML/` -- Additional modules (Entities, LinkExtor, HeadParser, etc.)
- `t/` -- Test suite (50 test files, 464 tests total)
- `eg/` -- Example scripts demonstrating usage
- `cpanfile` -- Dependency specification
- `Makefile.PL` -- Build configuration

### Important Modules:
- `HTML::Parser` -- Main parser class (lib/HTML/Parser.pm)
- `HTML::Entities` -- HTML entity encoding/decoding (lib/HTML/Entities.pm)
- `HTML::LinkExtor` -- Extract links from HTML (lib/HTML/LinkExtor.pm)
- `HTML::HeadParser` -- Parse HTML head sections (lib/HTML/HeadParser.pm)
- `HTML::PullParser` -- Pull-style parsing interface (lib/HTML/PullParser.pm)

## Testing

- Test suite is comprehensive with 464 tests across multiple scenarios
- Tests cover: basic parsing, entity handling, filters, callbacks, edge cases
- All tests use Test::More framework
- Key test categories:
  - Parser functionality (t/parser.t, t/callback.t)
  - Entity handling (t/entities.t, t/uentities.t)
  - Filter methods (t/filter.t, t/filter-methods.t)
  - Unicode support (t/unicode.t)
  - Various parser modes and options

## Common Tasks

### Building from scratch:
```bash
perl Makefile.PL
make
make test
```

### Testing specific functionality:
```bash
# Test entity handling
perl -MHTML::Entities -e 'print HTML::Entities::encode_entities("<test>") . "\n"'

# Test basic parsing
perl -MHTML::Parser -e '
  my $p = HTML::Parser->new(text_h => [sub { print "$_[0]\n" }, "dtext"]);
  $p->parse("<p>Hello &amp; world</p>");
  $p->eof;
'
```

### Manual validation scenarios:
1. **Basic HTML parsing**: Create HTML with tags, attributes, text, and entities. Parse and verify all components are extracted correctly.
2. **Entity decoding**: Test HTML entities like &amp;, &lt;, &gt;, &#39; are properly decoded.
3. **Filter functionality**: Test ignore_tags, report_tags, and ignore_elements work correctly.
4. **Callback handling**: Verify start_h, end_h, text_h callbacks receive correct parameters.

### File outputs from commonly run commands:

#### Repository root listing:
```
Changes          TODO             dist.ini         hparser.c        lib/             t/
LICENSE          cpanfile         eg/              hparser.h        mkhctype         test.html
Makefile.PL      .github/         entities.html    hints/           mkpfunc          test_parser.pl
META.json        .gitignore       .perltidyrc      typemap          Parser.xs        tokenpos.h
README.md        .mailmap         hctype.h         pfunc.h          ppport.h         util.c
```

#### Example scripts (eg/ directory):
```
hanchors  hbody  hdisable  hdump  hform  hlc  hrefsub  hstrip  htext  htextsub  htitle
```

#### Test directory:
- 50 test files covering all functionality
- Tests range from basic parsing to complex Unicode scenarios
- All tests must pass for a valid build

## CI/CD

- GitHub Actions workflows for Linux, macOS, and Windows
- Workflows test multiple Perl versions (5.10 to 5.40)
- All builds must pass before merge
- Located in .github/workflows/

## Development Notes

- This is a mature, stable codebase (version 3.84)
- Changes should be minimal and well-tested
- XS/C code changes require careful validation
- Backward compatibility is important
- Follow existing code style (see .perltidyrc)

## Performance

- Parser is optimized for speed with C implementation
- Handles large documents efficiently
- Event-driven approach minimizes memory usage
- Build times are fast (~1.5 seconds total)
- Test execution is quick (~3 seconds for full suite)

## Troubleshooting

- If build fails, ensure C compiler is available
- Missing dependencies are usually auto-detected
- Test failures indicate breaking changes
- XS compilation errors suggest C code issues
- Use `make clean` to reset build state