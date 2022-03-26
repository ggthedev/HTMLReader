//  HTMLEncoding.m
//
//  Public domain. https://github.com/nolanw/HTMLReader

#import "HTMLEncoding+Private.h"

/**
 * Returns the name of an encoding given by a label, as specified in the WHATWG Encoding standard, or nil if the label has no associated name.
 *
 * For more information, see https://encoding.spec.whatwg.org/#names-and-labels
 */
static NSString * NamedEncodingForLabel(NSString *label);

/**
 * Returns the string encoding given by a name from the WHATWG Encoding Standard, or the result of HTMLInvalidStringEncoding() if there is no known encoding given by name.
 */
static NSStringEncoding StringEncodingForName(NSString *name);

HTMLStringEncoding DeterminedStringEncodingForData(NSData *data, NSString *contentType, NSString **outDecodedString)
{
    unsigned char buffer[3] = {0};
    [data getBytes:buffer length:MIN(data.length, 3U)];
    if (buffer[0] == 0xFE && buffer[1] == 0xFF) {
        NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF16BigEndianStringEncoding];
        if (decodedString) {
            *outDecodedString = decodedString;
            return (HTMLStringEncoding){
                .encoding = NSUTF16BigEndianStringEncoding,
                .confidence = Certain
            };
        }
    } else if (buffer[0] == 0xFF && buffer[1] == 0xFE) {
        NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF16LittleEndianStringEncoding];
        if (decodedString) {
            *outDecodedString = decodedString;
            return (HTMLStringEncoding){
                .encoding = NSUTF16LittleEndianStringEncoding,
                .confidence = Certain
            };
        }
    } else if (buffer[0] == 0xEF && buffer[1] == 0xBB && buffer[2] == 0xBF) {
        NSString *decodedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (decodedString) {
            *outDecodedString = decodedString;
            return (HTMLStringEncoding){
                .encoding = NSUTF8StringEncoding,
                .confidence = Certain
            };
        }
    }
    
    if (contentType) {
        // http://tools.ietf.org/html/rfc7231#section-3.1.1.1
        NSScanner *scanner = [NSScanner scannerWithString:contentType];
        [scanner scanUpToString:@"charset=" intoString:nil];
        if ([scanner scanString:@"charset=" intoString:nil]) {
            [scanner scanString:@"\"" intoString:nil];
            NSString *encodingLabel;
            if ([scanner scanUpToString:@"\"" intoString:&encodingLabel]) {
                NSStringEncoding encoding = HTMLStringEncodingForLabel(encodingLabel);
                if (encoding != HTMLInvalidStringEncoding()) {
                    NSString *decodedString = [[NSString alloc] initWithData:data encoding:encoding];
                    if (decodedString) {
                        *outDecodedString = decodedString;
                        return (HTMLStringEncoding){
                            .encoding = encoding,
                            .confidence = Certain
                        };
                    }
                }
            }
        }
    }
    
    // TODO Prescan?
    
    // TODO There's a table down in step 9 of https://html.spec.whatwg.org/multipage/syntax.html#documentEncoding that describes default encodings based on the current locale. Maybe implement that.

    // https://encoding.spec.whatwg.org/index-windows-1252.txt maps the unused positions to control code points. html5lib-python maps to U+FFFD REPLACEMENT CHARACTER. NSString's usual decoding of win1252 rejects unused positions entirely. If we can convince NSString to do a lossy conversion, that matches html5lib-python and seems close enough.
    if (UsesLossyWindows1252Decoding()) {
        NSString *win1252;
        NSDictionary *encodingOptions = @{
            NSStringEncodingDetectionSuggestedEncodingsKey: @[@(NSWindowsCP1252StringEncoding)],
            NSStringEncodingDetectionUseOnlySuggestedEncodingsKey: @YES,
        };
        NSStringEncoding result = [NSString stringEncodingForData:data
                                                  encodingOptions:encodingOptions
                                                  convertedString:&win1252
                                              usedLossyConversion:nil];
        // This is not expected or known to fail, but let's check anyway.
        if (result != 0) {
            *outDecodedString = win1252;
            return (HTMLStringEncoding){
                .encoding = NSWindowsCP1252StringEncoding,
                .confidence = Tentative
            };
        }
    } else {
        // win1252 has some unused positions that NSString rejects, so it's not a guarantee that it'll work.
        NSString *win1252 = [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
        if (win1252) {
            *outDecodedString = win1252;
            return (HTMLStringEncoding){
                .encoding = NSWindowsCP1252StringEncoding,
                .confidence = Tentative
            };
        }
    }

    // iso8859-1 is the closest analog to win1252 that always decodes.
    *outDecodedString = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    return (HTMLStringEncoding){
        .encoding = NSISOLatin1StringEncoding,
        .confidence = Tentative
    };
}

typedef struct {
    __unsafe_unretained NSString *label;
    __unsafe_unretained NSString *name;
} EncodingLabelMap;

// This array is generated by the Encoding Labeler utility. Please don't make adjustments here.
static const EncodingLabelMap EncodingLabels[] = {
    { @"866", @"IBM866" },
    { @"ansi_x3.4-1968", @"windows-1252" },
    { @"arabic", @"ISO-8859-6" },
    { @"ascii", @"windows-1252" },
    { @"asmo-708", @"ISO-8859-6" },
    { @"big5", @"Big5" },
    { @"big5-hkscs", @"Big5" },
    { @"chinese", @"GBK" },
    { @"cn-big5", @"Big5" },
    { @"cp1250", @"windows-1250" },
    { @"cp1251", @"windows-1251" },
    { @"cp1252", @"windows-1252" },
    { @"cp1253", @"windows-1253" },
    { @"cp1254", @"windows-1254" },
    { @"cp1255", @"windows-1255" },
    { @"cp1256", @"windows-1256" },
    { @"cp1257", @"windows-1257" },
    { @"cp1258", @"windows-1258" },
    { @"cp819", @"windows-1252" },
    { @"cp866", @"IBM866" },
    { @"csbig5", @"Big5" },
    { @"cseuckr", @"EUC-KR" },
    { @"cseucpkdfmtjapanese", @"EUC-JP" },
    { @"csgb2312", @"GBK" },
    { @"csibm866", @"IBM866" },
    { @"csiso2022jp", @"ISO-2022-JP" },
    { @"csiso2022kr", @"replacement" },
    { @"csiso58gb231280", @"GBK" },
    { @"csiso88596e", @"ISO-8859-6" },
    { @"csiso88596i", @"ISO-8859-6" },
    { @"csiso88598e", @"ISO-8859-8" },
    { @"csiso88598i", @"ISO-8859-8-I" },
    { @"csisolatin1", @"windows-1252" },
    { @"csisolatin2", @"ISO-8859-2" },
    { @"csisolatin3", @"ISO-8859-3" },
    { @"csisolatin4", @"ISO-8859-4" },
    { @"csisolatin5", @"windows-1254" },
    { @"csisolatin6", @"ISO-8859-10" },
    { @"csisolatin9", @"ISO-8859-15" },
    { @"csisolatinarabic", @"ISO-8859-6" },
    { @"csisolatincyrillic", @"ISO-8859-5" },
    { @"csisolatingreek", @"ISO-8859-7" },
    { @"csisolatinhebrew", @"ISO-8859-8" },
    { @"cskoi8r", @"KOI8-R" },
    { @"csksc56011987", @"EUC-KR" },
    { @"csmacintosh", @"macintosh" },
    { @"csshiftjis", @"Shift_JIS" },
    { @"cyrillic", @"ISO-8859-5" },
    { @"dos-874", @"windows-874" },
    { @"ecma-114", @"ISO-8859-6" },
    { @"ecma-118", @"ISO-8859-7" },
    { @"elot_928", @"ISO-8859-7" },
    { @"euc-jp", @"EUC-JP" },
    { @"euc-kr", @"EUC-KR" },
    { @"gb18030", @"gb18030" },
    { @"gb2312", @"GBK" },
    { @"gb_2312", @"GBK" },
    { @"gb_2312-80", @"GBK" },
    { @"gbk", @"GBK" },
    { @"greek", @"ISO-8859-7" },
    { @"greek8", @"ISO-8859-7" },
    { @"hebrew", @"ISO-8859-8" },
    { @"hz-gb-2312", @"replacement" },
    { @"ibm819", @"windows-1252" },
    { @"ibm866", @"IBM866" },
    { @"iso-2022-cn", @"replacement" },
    { @"iso-2022-cn-ext", @"replacement" },
    { @"iso-2022-jp", @"ISO-2022-JP" },
    { @"iso-2022-kr", @"replacement" },
    { @"iso-8859-1", @"windows-1252" },
    { @"iso-8859-10", @"ISO-8859-10" },
    { @"iso-8859-11", @"windows-874" },
    { @"iso-8859-13", @"ISO-8859-13" },
    { @"iso-8859-14", @"ISO-8859-14" },
    { @"iso-8859-15", @"ISO-8859-15" },
    { @"iso-8859-16", @"ISO-8859-16" },
    { @"iso-8859-2", @"ISO-8859-2" },
    { @"iso-8859-3", @"ISO-8859-3" },
    { @"iso-8859-4", @"ISO-8859-4" },
    { @"iso-8859-5", @"ISO-8859-5" },
    { @"iso-8859-6", @"ISO-8859-6" },
    { @"iso-8859-6-e", @"ISO-8859-6" },
    { @"iso-8859-6-i", @"ISO-8859-6" },
    { @"iso-8859-7", @"ISO-8859-7" },
    { @"iso-8859-8", @"ISO-8859-8" },
    { @"iso-8859-8-e", @"ISO-8859-8" },
    { @"iso-8859-8-i", @"ISO-8859-8-I" },
    { @"iso-8859-9", @"windows-1254" },
    { @"iso-ir-100", @"windows-1252" },
    { @"iso-ir-101", @"ISO-8859-2" },
    { @"iso-ir-109", @"ISO-8859-3" },
    { @"iso-ir-110", @"ISO-8859-4" },
    { @"iso-ir-126", @"ISO-8859-7" },
    { @"iso-ir-127", @"ISO-8859-6" },
    { @"iso-ir-138", @"ISO-8859-8" },
    { @"iso-ir-144", @"ISO-8859-5" },
    { @"iso-ir-148", @"windows-1254" },
    { @"iso-ir-149", @"EUC-KR" },
    { @"iso-ir-157", @"ISO-8859-10" },
    { @"iso-ir-58", @"GBK" },
    { @"iso8859-1", @"windows-1252" },
    { @"iso8859-10", @"ISO-8859-10" },
    { @"iso8859-11", @"windows-874" },
    { @"iso8859-13", @"ISO-8859-13" },
    { @"iso8859-14", @"ISO-8859-14" },
    { @"iso8859-15", @"ISO-8859-15" },
    { @"iso8859-2", @"ISO-8859-2" },
    { @"iso8859-3", @"ISO-8859-3" },
    { @"iso8859-4", @"ISO-8859-4" },
    { @"iso8859-5", @"ISO-8859-5" },
    { @"iso8859-6", @"ISO-8859-6" },
    { @"iso8859-7", @"ISO-8859-7" },
    { @"iso8859-8", @"ISO-8859-8" },
    { @"iso8859-9", @"windows-1254" },
    { @"iso88591", @"windows-1252" },
    { @"iso885910", @"ISO-8859-10" },
    { @"iso885911", @"windows-874" },
    { @"iso885913", @"ISO-8859-13" },
    { @"iso885914", @"ISO-8859-14" },
    { @"iso885915", @"ISO-8859-15" },
    { @"iso88592", @"ISO-8859-2" },
    { @"iso88593", @"ISO-8859-3" },
    { @"iso88594", @"ISO-8859-4" },
    { @"iso88595", @"ISO-8859-5" },
    { @"iso88596", @"ISO-8859-6" },
    { @"iso88597", @"ISO-8859-7" },
    { @"iso88598", @"ISO-8859-8" },
    { @"iso88599", @"windows-1254" },
    { @"iso_8859-1", @"windows-1252" },
    { @"iso_8859-15", @"ISO-8859-15" },
    { @"iso_8859-1:1987", @"windows-1252" },
    { @"iso_8859-2", @"ISO-8859-2" },
    { @"iso_8859-2:1987", @"ISO-8859-2" },
    { @"iso_8859-3", @"ISO-8859-3" },
    { @"iso_8859-3:1988", @"ISO-8859-3" },
    { @"iso_8859-4", @"ISO-8859-4" },
    { @"iso_8859-4:1988", @"ISO-8859-4" },
    { @"iso_8859-5", @"ISO-8859-5" },
    { @"iso_8859-5:1988", @"ISO-8859-5" },
    { @"iso_8859-6", @"ISO-8859-6" },
    { @"iso_8859-6:1987", @"ISO-8859-6" },
    { @"iso_8859-7", @"ISO-8859-7" },
    { @"iso_8859-7:1987", @"ISO-8859-7" },
    { @"iso_8859-8", @"ISO-8859-8" },
    { @"iso_8859-8:1988", @"ISO-8859-8" },
    { @"iso_8859-9", @"windows-1254" },
    { @"iso_8859-9:1989", @"windows-1254" },
    { @"koi", @"KOI8-R" },
    { @"koi8", @"KOI8-R" },
    { @"koi8-r", @"KOI8-R" },
    { @"koi8-ru", @"KOI8-U" },
    { @"koi8-u", @"KOI8-U" },
    { @"koi8_r", @"KOI8-R" },
    { @"korean", @"EUC-KR" },
    { @"ks_c_5601-1987", @"EUC-KR" },
    { @"ks_c_5601-1989", @"EUC-KR" },
    { @"ksc5601", @"EUC-KR" },
    { @"ksc_5601", @"EUC-KR" },
    { @"l1", @"windows-1252" },
    { @"l2", @"ISO-8859-2" },
    { @"l3", @"ISO-8859-3" },
    { @"l4", @"ISO-8859-4" },
    { @"l5", @"windows-1254" },
    { @"l6", @"ISO-8859-10" },
    { @"l9", @"ISO-8859-15" },
    { @"latin1", @"windows-1252" },
    { @"latin2", @"ISO-8859-2" },
    { @"latin3", @"ISO-8859-3" },
    { @"latin4", @"ISO-8859-4" },
    { @"latin5", @"windows-1254" },
    { @"latin6", @"ISO-8859-10" },
    { @"logical", @"ISO-8859-8-I" },
    { @"mac", @"macintosh" },
    { @"macintosh", @"macintosh" },
    { @"ms932", @"Shift_JIS" },
    { @"ms_kanji", @"Shift_JIS" },
    { @"replacement", @"replacement" },
    { @"shift-jis", @"Shift_JIS" },
    { @"shift_jis", @"Shift_JIS" },
    { @"sjis", @"Shift_JIS" },
    { @"sun_eu_greek", @"ISO-8859-7" },
    { @"tis-620", @"windows-874" },
    { @"unicode-1-1-utf-8", @"UTF-8" },
    { @"us-ascii", @"windows-1252" },
    { @"utf-16", @"UTF-16LE" },
    { @"utf-16be", @"UTF-16BE" },
    { @"utf-16le", @"UTF-16LE" },
    { @"utf-8", @"UTF-8" },
    { @"utf8", @"UTF-8" },
    { @"visual", @"ISO-8859-8" },
    { @"windows-1250", @"windows-1250" },
    { @"windows-1251", @"windows-1251" },
    { @"windows-1252", @"windows-1252" },
    { @"windows-1253", @"windows-1253" },
    { @"windows-1254", @"windows-1254" },
    { @"windows-1255", @"windows-1255" },
    { @"windows-1256", @"windows-1256" },
    { @"windows-1257", @"windows-1257" },
    { @"windows-1258", @"windows-1258" },
    { @"windows-31j", @"Shift_JIS" },
    { @"windows-874", @"windows-874" },
    { @"windows-949", @"EUC-KR" },
    { @"x-cp1250", @"windows-1250" },
    { @"x-cp1251", @"windows-1251" },
    { @"x-cp1252", @"windows-1252" },
    { @"x-cp1253", @"windows-1253" },
    { @"x-cp1254", @"windows-1254" },
    { @"x-cp1255", @"windows-1255" },
    { @"x-cp1256", @"windows-1256" },
    { @"x-cp1257", @"windows-1257" },
    { @"x-cp1258", @"windows-1258" },
    { @"x-euc-jp", @"EUC-JP" },
    { @"x-gbk", @"GBK" },
    { @"x-mac-cyrillic", @"x-mac-cyrillic" },
    { @"x-mac-roman", @"macintosh" },
    { @"x-mac-ukrainian", @"x-mac-cyrillic" },
    { @"x-sjis", @"Shift_JIS" },
    { @"x-user-defined", @"x-user-defined" },
    { @"x-x-big5", @"Big5" },
};

static int (^EncodingLabelComparator)(const void *, const void *) = ^int(const void *voidKey, const void *voidItem) {
    const NSString *key = (__bridge const NSString *)voidKey;
    const EncodingLabelMap *item = voidItem;
    return (int)[key caseInsensitiveCompare:item->label];
};

static NSString * NamedEncodingForLabel(NSString *label)
{
    EncodingLabelMap *match = bsearch_b((__bridge const void *)label, EncodingLabels, sizeof(EncodingLabels) / sizeof(EncodingLabels[0]), sizeof(EncodingLabels[0]), EncodingLabelComparator);
    if (match) {
        return match->name;
    } else {
        return nil;
    }
}

typedef struct {
    __unsafe_unretained NSString *name;
    CFStringEncoding encoding;
} NameCFEncodingMap;

// This array is generated by the Encoding Labeler utility. Please make adjustments over there, not over here.
static const NameCFEncodingMap StringEncodings[] = {
    { @"Big5", kCFStringEncodingBig5 },
    { @"EUC-JP", kCFStringEncodingEUC_JP },
    { @"EUC-KR", kCFStringEncodingEUC_KR },
    { @"GBK", kCFStringEncodingGBK_95 },
    { @"IBM866", kCFStringEncodingDOSRussian },
    { @"ISO-2022-JP", kCFStringEncodingISO_2022_JP },
    { @"ISO-8859-10", kCFStringEncodingISOLatin6 },
    { @"ISO-8859-13", kCFStringEncodingISOLatin7 },
    { @"ISO-8859-14", kCFStringEncodingISOLatin8 },
    { @"ISO-8859-15", kCFStringEncodingISOLatin9 },
    { @"ISO-8859-16", kCFStringEncodingISOLatin10 },
    { @"ISO-8859-2", kCFStringEncodingISOLatin2 },
    { @"ISO-8859-3", kCFStringEncodingISOLatin3 },
    { @"ISO-8859-4", kCFStringEncodingISOLatin4 },
    { @"ISO-8859-5", kCFStringEncodingISOLatinCyrillic },
    { @"ISO-8859-6", kCFStringEncodingISOLatinArabic },
    { @"ISO-8859-7", kCFStringEncodingISOLatinGreek },
    { @"ISO-8859-8", kCFStringEncodingISOLatinHebrew },
    { @"ISO-8859-8-I", kCFStringEncodingISOLatinHebrew },
    { @"KOI8-R", kCFStringEncodingKOI8_R },
    { @"KOI8-U", kCFStringEncodingKOI8_U },
    { @"Shift_JIS", kCFStringEncodingShiftJIS },
    { @"UTF-16BE", kCFStringEncodingUTF16BE },
    { @"UTF-16LE", kCFStringEncodingUTF16LE },
    { @"UTF-8", kCFStringEncodingUTF8 },
    { @"gb18030", kCFStringEncodingGB_18030_2000 },
    { @"macintosh", kCFStringEncodingMacRoman },
    { @"replacement", kCFStringEncodingInvalidId },
    { @"windows-1250", kCFStringEncodingWindowsLatin2 },
    { @"windows-1251", kCFStringEncodingWindowsCyrillic },
    { @"windows-1252", kCFStringEncodingWindowsLatin1 },
    { @"windows-1253", kCFStringEncodingWindowsGreek },
    { @"windows-1254", kCFStringEncodingWindowsLatin5 },
    { @"windows-1255", kCFStringEncodingWindowsHebrew },
    { @"windows-1256", kCFStringEncodingWindowsArabic },
    { @"windows-1257", kCFStringEncodingWindowsBalticRim },
    { @"windows-1258", kCFStringEncodingWindowsVietnamese },
    { @"windows-874", kCFStringEncodingDOSThai },
    { @"x-mac-cyrillic", kCFStringEncodingMacCyrillic },
    // SPEC: The HTML standard unilaterally changes x-user-defined to windows-1252, so let's just define it so.
    { @"x-user-defined", kCFStringEncodingWindowsLatin1 },
};

static int (^NameCFEncodingComparator)(const void *, const void *) = ^int(const void *voidKey, const void *voidItem) {
    const NSString *key = (__bridge const NSString *)voidKey;
    const NameCFEncodingMap *item = voidItem;
    return (int)[key compare:item->name];
};

static NSStringEncoding StringEncodingForName(NSString *name)
{
    NameCFEncodingMap *match = bsearch_b((__bridge const void *)name, StringEncodings, sizeof(StringEncodings) / sizeof(StringEncodings[0]), sizeof(StringEncodings[0]), NameCFEncodingComparator);
    if (match) {
        return CFStringConvertEncodingToNSStringEncoding(match->encoding);
    } else {
        return HTMLInvalidStringEncoding();
    }
}

NSStringEncoding HTMLInvalidStringEncoding(void)
{
    return CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingInvalidId);
}

NSStringEncoding HTMLStringEncodingForLabel(NSString *untrimmedLabel)
{
    NSString *label = [untrimmedLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *name = NamedEncodingForLabel(label);
    if (name) {
        return StringEncodingForName(name);
    } else {
        return HTMLInvalidStringEncoding();
    }
}

BOOL IsASCIICompatibleEncoding(NSStringEncoding nsencoding)
{
    CFStringEncoding encoding = CFStringConvertNSStringEncodingToEncoding(nsencoding);
    switch (encoding) {
        // TODO This is a bespoke list, as I couldn't find a handy list from WHATWG or elsewhere. I guess we could code up their definition of "ASCII-compatible" and run through the list of known string encodings?
        case kCFStringEncodingUTF7:
        case kCFStringEncodingUTF16:
        case kCFStringEncodingUTF16BE:
        case kCFStringEncodingUTF16LE:
        case kCFStringEncodingHZ_GB_2312:
        case kCFStringEncodingUTF7_IMAP:
            return NO;
        default:
            return YES;
    }
}

BOOL IsUTF16Encoding(NSStringEncoding encoding)
{
    switch (encoding) {
        case NSUTF16BigEndianStringEncoding:
        case NSUTF16LittleEndianStringEncoding:
            return YES;
        default:
            return NO;
    }
}

BOOL UsesLossyWindows1252Decoding(void)
{
    #if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 80000) || (__MAC_OS_X_VERSION_MAX_ALLOWED >= 101000)
    return [[NSString class] respondsToSelector:@selector(stringEncodingForData:encodingOptions:convertedString:usedLossyConversion:)];
    #else
    return NO;
    #endif
}
