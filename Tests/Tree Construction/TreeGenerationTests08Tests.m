// This file was autogenerated from Tests/html5lib/tree-construction/tests8.dat

#import <SenTestingKit/SenTestingKit.h>
#import "HTMLTreeConstructionTestUtilities.h"

@interface TreeGenerationTests08Tests : SenTestCase

@end

@implementation TreeGenerationTests08Tests

- (void)test000
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"<div>\n<div></div>\n</span>x" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     <div>\n|       \"\n");
    STAssertTrue(parser.errors.count == 3 && [parser.document.childNodes isEqual:fixture], nil);
}

- (void)test001
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"<div>x<div></div>\n</span>x" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     <div>\n|       \"x\"\n|       <div>\n|       \"\n");
    STAssertTrue(parser.errors.count == 3 && [parser.document.childNodes isEqual:fixture], nil);
}

- (void)test002
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"<div>x<div></div>x</span>x" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     <div>\n|       \"x\"\n|       <div>\n|       \"xx\"\n");
    STAssertTrue(parser.errors.count == 3 && [parser.document.childNodes isEqual:fixture], nil);
}

- (void)test003
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"<div>x<div></div>y</span>z" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     <div>\n|       \"x\"\n|       <div>\n|       \"yz\"\n");
    STAssertTrue(parser.errors.count == 3 && [parser.document.childNodes isEqual:fixture], nil);
}

- (void)test004
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"<table><div>x<div></div>x</span>x" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     <div>\n|       \"x\"\n|       <div>\n|       \"xx\"\n|     <table>\n");
    STAssertTrue(parser.errors.count == 7 && [parser.document.childNodes isEqual:fixture], nil);
}

- (void)test005
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"x<table>x" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     \"xx\"\n|     <table>\n");
    STAssertTrue(parser.errors.count == 3 && [parser.document.childNodes isEqual:fixture], nil);
}

- (void)test006
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"x<table><table>x" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     \"x\"\n|     <table>\n|     \"x\"\n|     <table>\n");
    STAssertTrue(parser.errors.count == 4 && [parser.document.childNodes isEqual:fixture], nil);
}

- (void)test007
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"<b>a<div></div><div></b>y" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     <b>\n|       \"a\"\n|       <div>\n|     <div>\n|       <b>\n|       \"y\"\n");
    STAssertTrue(parser.errors.count == 3 && [parser.document.childNodes isEqual:fixture], nil);
}

- (void)test008
{
    HTMLParser *parser = [[HTMLParser alloc] initWithString:@"<a><div><p></a>" context:nil];
    NSArray *fixture = ReifiedTreeForTestDocument(@"| <html>\n|   <head>\n|   <body>\n|     <a>\n|     <div>\n|       <a>\n|       <p>\n|         <a>\n");
    STAssertTrue(parser.errors.count == 4 && [parser.document.childNodes isEqual:fixture], nil);
}

@end