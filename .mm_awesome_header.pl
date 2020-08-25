my %xsbuild = (
    DEFINE => "-DMARKED_SECTION",
    H      => [
        "hparser.h", "hctype.h", "tokenpos.h", "pfunc.h",
        "hparser.c", "util.c",
    ],
);
