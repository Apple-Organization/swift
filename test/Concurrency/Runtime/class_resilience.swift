// RUN: %empty-directory(%t)

// RUN: %target-build-swift-dylib(%t/%target-library-name(resilient_class)) -Xfrontend -enable-experimental-concurrency -enable-library-evolution %S/Inputs/resilient_class.swift -emit-module -emit-module-path %t/resilient_class.swiftmodule -module-name resilient_class
// RUN: %target-codesign %t/%target-library-name(resilient_class)

// RUN: %target-build-swift -Xfrontend -enable-experimental-concurrency %s -lresilient_class -I %t -L %t -o %t/main %target-rpath(%t)
// RUN: %target-codesign %t/main

// RUN: %target-run %t/main %t/%target-library-name(resilient_class)

// REQUIRES: executable_test
// REQUIRES: concurrency

// rdar://76038845
// UNSUPPORTED: use_os_stdlib
// UNSUPPORTED: back_deployment_runtime

// XFAIL: windows
// XFAIL: linux
// XFAIL: openbsd

import StdlibUnittest
import resilient_class

class MyDerived : BaseClass<Int> {
  override func waitForNothing() async {
    await super.waitForNothing()
  }

  override func wait() async -> Int {
    return await super.wait() * 2
  }

  override func waitForInt() async -> Int {
    return await super.waitForInt() * 2
  }

  override func wait(orThrow: Bool) async throws {
    return try await super.wait(orThrow: orThrow)
  }
}

func virtualWaitForNothing<T>(_ c: BaseClass<T>) async {
  await c.waitForNothing()
}

func virtualWait<T>(_ c: BaseClass<T>) async -> T {
  return await c.wait()
}

func virtualWaitForInt<T>(_ c: BaseClass<T>) async -> Int {
  return await c.waitForInt()
}

func virtualWait<T>(orThrow: Bool, _ c: BaseClass<T>) async throws {
  return try await c.wait(orThrow: orThrow)
}

var AsyncVTableMethodSuite = TestSuite("ResilientClass")

AsyncVTableMethodSuite.test("AsyncVTableMethod") {
  runAsyncAndBlock {
    let x = MyDerived(value: 321)

    await virtualWaitForNothing(x)

    expectEqual(642, await virtualWait(x))
    expectEqual(246, await virtualWaitForInt(x))

    expectNil(try? await virtualWait(orThrow: true, x))
    try! await virtualWait(orThrow: false, x)
  }
}

runAllTests()
