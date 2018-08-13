import XCTest

import NIODatadogStatsdTests

var tests = [XCTestCaseEntry]()
tests += NIODatadogStatsdTests.allTests()
XCTMain(tests)