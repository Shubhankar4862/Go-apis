// Copyright 2015 The Serulian Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Based on design first introduced in: http://blog.golang.org/two-go-talks-lexical-scanning-in-go-and
// Portions copied and modified from: https://github.com/golang/go/blob/master/src/text/template/parse/lex.go

// This is a *generic* implementation of a lexer. gengen should be used to create a specific version of this lexer.
// If this file does not contain the gengen package, then it has already been generated by gengen.
// TODO: remove this hack if/when golang ever supports proper generics.
package parser

import (
	"fmt"
	"strings"
	"unicode"
	"unicode/utf8"
)

const EOFRUNE = -1

type isWhitespaceTokenChecker func(kind tokenType) bool
type lexSourceImpl func(l *lexer) stateFn

// buildlex creates a new scanner for the input string.
func buildlex(input string, impl lexSourceImpl, whitespace isWhitespaceTokenChecker) *lexer {
	l := &lexer{
		input:             input,
		tokens:            make(chan lexeme),
		isWhitespaceToken: whitespace,
		lexSource:         impl,
		line:              1,
		startLine:         1,
	}
	go l.run()
	return l
}

// run runs the state machine for the lexer.
func (l *lexer) run() {
	for l.state = lexSource; l.state != nil; {
		l.state = l.state(l)
	}
	close(l.tokens)
}

// bytePosition represents the byte position in a piece of code.
type bytePosition int
type lineNumber int

// lexeme represents a token returned from scanning the contents of a file.
type lexeme struct {
	kind     tokenType    // The type of this lexeme.
	position bytePosition // The starting position of this token in the input string.
	line     lineNumber   // Line number for starting position
	value    string       // The textual value of this token.
}

func (l lexeme) String() string {
	return fmt.Sprintf("inp:%d:%d - %v(%s)", l.line, l.position, l.kind, l.value)
}

// stateFn represents the state of the scanner as a function that returns the next state.
type stateFn func(*lexer) stateFn

// lexer holds the state of the scanner.
type lexer struct {
	input                  string       // the string being scanned
	state                  stateFn      // the next lexing function to enter
	pos                    bytePosition // current position in the input
	start                  bytePosition // start position of this token
	width                  bytePosition // width of last rune read from input
	lastPos                bytePosition // position of most recent token returned by nextToken
	tokens                 chan lexeme  // channel of scanned lexemes
	currentToken           lexeme       // The current token if any
	lastNonWhitespaceToken lexeme       // The last token returned that is non-whitespace
	line                   lineNumber   // current line number
	startLine              lineNumber   // line number for next token
	nextWasNL              bool         // last next() was a new line rune

	isWhitespaceToken isWhitespaceTokenChecker
	lexSource         lexSourceImpl
}

// nextToken returns the next token from the input.
func (l *lexer) nextToken() lexeme {
	token := <-l.tokens
	l.lastPos = token.position
	return token
}

// next returns the next rune in the input.
func (l *lexer) next() rune {
	if int(l.pos) >= len(l.input) {
		l.width = 0
		return EOFRUNE
	}
	r, w := utf8.DecodeRuneInString(l.input[l.pos:])
	l.width = bytePosition(w)
	l.pos += l.width
	l.nextWasNL = false
	if r == '\n' {
		l.line++
		l.nextWasNL = true
	}
	return r
}

// peek returns but does not consume the next rune in the input.
func (l *lexer) peek() rune {
	r := l.next()
	l.backup()
	return r
}

// peekValue looks forward for the given value string. If found, returns true.
func (l *lexer) peekValue(value string) bool {
	for index, runeValue := range value {
		r := l.next()
		if r != runeValue {
			for j := 0; j <= index; j++ {
				l.backup()
			}
			return false
		}
	}

	for i := 0; i < len(value); i++ {
		l.backup()
	}

	return true
}

// backup steps back one rune. Can only be called once per call of next.
func (l *lexer) backup() {
	l.pos -= l.width
	if l.nextWasNL {
		l.line--
	}
}

// value returns the current value of the token in the lexer.
func (l *lexer) value() string {
	return l.input[l.start:l.pos]
}

// emit passes an token back to the client.
func (l *lexer) emit(t tokenType) {
	l.emitWith(t, l.value())
}

func (l *lexer) emitWith(t tokenType, val string) {
	currentToken := lexeme{t, l.start, l.startLine, val}

	if l.isWhitespaceToken(t) {
		l.lastNonWhitespaceToken = currentToken
	}

	l.tokens <- currentToken
	l.currentToken = currentToken
	l.start = l.pos
	l.startLine = l.line
}

// errorf returns an error token and terminates the scan by passing
// back a nil pointer that will be the next state, terminating l.nexttoken.
func (l *lexer) errorf(format string, args ...interface{}) stateFn {
	l.tokens <- lexeme{tokenTypeError, l.start, l.startLine, fmt.Sprintf(format, args...)}
	return nil
}

// ignore skips over the pending input before this point.
func (l *lexer) ignore() {
	l.start = l.pos
	l.startLine = l.line
}

// accept consumes the next rune if it's from the valid set.
func (l *lexer) accept(valid string) bool {
	if strings.IndexRune(valid, l.next()) >= 0 {
		return true
	}
	l.backup()
	return false
}

// acceptRun consumes a run of runes from the valid set.
func (l *lexer) acceptRun(valid string) {
	for strings.IndexRune(valid, l.next()) >= 0 {
	}
	l.backup()
}

// acceptRun consumes the full given string, if the next tokens in the stream.
func (l *lexer) acceptString(value string) bool {
	for index, runeValue := range value {
		if l.next() != runeValue {
			for i := 0; i <= index; i++ {
				l.backup()
			}

			return false
		}
	}

	return true
}

// lexSource scans until EOFRUNE
func lexSource(l *lexer) stateFn {
	return l.lexSource(l)
}

// checkFn returns whether a rune matches for continue looping.
type checkFn func(r rune) (bool, error)

func buildLexUntil(findType tokenType, checker checkFn) stateFn {
	return func(l *lexer) stateFn {
		for {
			r := l.next()
			is_valid, err := checker(r)
			if err != nil {
				return l.errorf("%v", err)
			}
			if !is_valid {
				l.backup()
				break
			}
		}

		l.emit(findType)
		return lexSource
	}
}

// lexNumber scans a number: decimal, octal, hex, float, or imaginary. This
// isn't a perfect number scanner - for instance it accepts "." and "0x0.2"
// and "089" - but when it's wrong the input is invalid and the parser (via
// strconv) will notice.
func lexNumber(l *lexer) stateFn {
	if !l.scanNumber() {
		return l.errorf("bad number syntax: %q", l.input[l.start:l.pos])
	}
	l.emit(tokenTypeNumber)
	return lexSource
}

func (l *lexer) scanNumber() bool {
	// Optional leading sign.
	l.accept("+-")
	// Is it hex?
	digits := "0123456789"
	if l.accept("0") && l.accept("xX") {
		digits = "0123456789abcdefABCDEF"
	}
	l.acceptRun(digits)
	if l.accept(".") {
		l.acceptRun(digits)
	}
	if l.accept("eE") {
		l.accept("+-")
		l.acceptRun("0123456789")
	}
	// Next thing mustn't be alphanumeric.
	if isAlphaNumeric(l.peek()) {
		l.next()
		return false
	}
	return true
}

// isSpace reports whether r is a space character.
func isSpace(r rune) bool {
	return r == ' ' || r == '\t'
}

// isNewline reports whether r is a newline character.
func isNewline(r rune) bool {
	return r == '\r' || r == '\n'
}

func isNumber(r rune) bool {
	return r == '+' || r == '-' || unicode.IsDigit(r)
}

// isAlphaNumeric reports whether r is an alphabetic, digit, or underscore.
func isAlphaNumeric(r rune) bool {
	return r == '_' || unicode.IsLetter(r) || unicode.IsDigit(r)
}
