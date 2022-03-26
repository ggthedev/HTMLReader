//  HTMLEncoding+Private.h
//
//  Public domain. https://github.com/nolanw/HTMLReader

#import "HTMLEncoding.h"

/// Tags a string encoding with a confidence that the parser can use to help determine how to decode bytes into a document.
typedef struct {
    NSStringEncoding encoding;
    enum {
        Tentative,
        Certain,
        Irrelevant
    } confidence;
} HTMLStringEncoding;

/**
    Returns a string encoding that likely encodes the data.
 
    @param contentType   The value of the HTTP Content-Type header, if present.
    @param outDecodedString On return, contains the string decoded as the determined string encoding.
 
    For more information, see https://html.spec.whatwg.org/multipage/syntax.html#determining-the-character-encoding
 */
extern HTMLStringEncoding DeterminedStringEncodingForData(NSData *data, NSString *contentType, NSString **outDecodedString);

/**
    Returns YES if encoding "is a single-byte or variable-length encoding in which the bytes 0x09, 0x0A, 0x0C, 0x0D, 0x20 - 0x22, 0x26, 0x27, 0x2C - 0x3F, 0x41 - 0x5A, and 0x61 - 0x7A, ignoring bytes that are the second and later bytes of multibyte sequences, all correspond to single-byte sequences that map to the same Unicode characters as those bytes in Windows-1252".
 
    For more information, see https://html.spec.whatwg.org/multipage/infrastructure.html#ascii-compatible-character-encoding
 */
extern BOOL IsASCIICompatibleEncoding(NSStringEncoding encoding);

/// Returns YES if encoding is UTF16-LE or UTF16-BE.
extern BOOL IsUTF16Encoding(NSStringEncoding encoding);

/// Returns YES if Windows-1252 encoding is used even when characters are found at unused positions in the code page. (The relevant NSString API to enable this appeared in iOS 8 and Mac OS X 10.10.)
extern BOOL UsesLossyWindows1252Decoding(void);
