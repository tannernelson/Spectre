public protocol ExpectationType {
  typealias ValueType
  var expression: () throws -> ValueType? { get }
  func failure(reason: String) -> FailureType
}

struct ExpectationFailure : FailureType {
  let file: String
  let line: Int
  let function: String

  let reason: String

  init(reason: String, file: String, line: Int, function: String) {
    self.reason = reason
    self.file = file
    self.line = line
    self.function = function
  }
}

public class Expectation<T> : ExpectationType {
  public typealias ValueType = T
  public let expression: () throws -> ValueType?

  let file: String
  let line: Int
  let function: String

  public var to: Expectation<T> {
    return self
  }

  init(file: String, line: Int, function: String, expression: () throws -> ValueType?) {
    self.file = file
    self.line = line
    self.function = function
    self.expression = expression
  }

  public func failure(reason: String) -> FailureType {
    return ExpectationFailure(reason: reason, file: file, line: line, function: function)
  }
}

public func expect<T>(@autoclosure(escaping) expression: () throws -> T?, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) -> Expectation<T> {
  return Expectation(file: file, line: line, function: function, expression: expression)
}

public func expect<T>(file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__, expression: () throws -> T?)  -> Expectation<T> {
  return Expectation(file: file, line: line, function: function, expression: expression)
}

// MARK: Equatability

public func == <E: ExpectationType where E.ValueType: Equatable>(lhs: E, rhs: E.ValueType) throws {
  if let value = try lhs.expression() {
    if value != rhs {
      throw lhs.failure("\(value) is not equal to \(rhs)")
    }
  } else {
    throw lhs.failure("given value is nil")
  }
}

public func != <E: ExpectationType where E.ValueType: Equatable>(lhs: E, rhs: E.ValueType) throws {
  let value = try lhs.expression()
  if value == rhs {
    throw lhs.failure("\(value) is equal to \(rhs)")
  }
}

// MARK: Nil

extension ExpectationType {
  public func beNil() throws {
    let value = try expression()
    if value != nil {
      throw failure("value is not nil")
    }
  }
}

// MARK: Boolean

extension ExpectationType where ValueType == Bool {
  public func beTrue() throws {
    let value = try expression()
    if value != true {
      throw failure("value is not true")
    }
  }

  public func beFalse() throws {
    let value = try expression()
    if value != false {
      throw failure("value is not false")
    }
  }
}

// MARK: Error Handling

extension ExpectationType {
  public func toThrow() throws {
    var didThrow = false

    do {
      try expression()
    } catch {
      didThrow = true
    }

    if !didThrow {
      throw failure("expression did not throw an error")
    }
  }

  public func toThrow<T: Equatable>(error: T) throws {
    var thrownError: ErrorType? = nil

    do {
      try expression()
    } catch {
      thrownError = error
    }

    if let thrownError = thrownError {
      if let thrownError = thrownError as? T {
        if error != thrownError {
          throw failure("\(thrownError) is not \(error)")
        }
      } else {
        throw failure("\(thrownError) is not \(error)")
      }
    } else {
      throw failure("expression did not throw an error")
    }
  }
}

// MARK: Comparable

public func > <E: ExpectationType where E.ValueType: Comparable>(lhs: E, rhs: E.ValueType) throws {
  let value = try lhs.expression()
  guard value > rhs else {
    throw lhs.failure("\(value) is not more than \(rhs)")
  }
}

public func >= <E: ExpectationType where E.ValueType: Comparable>(lhs: E, rhs: E.ValueType) throws {
  let value = try lhs.expression()
  guard value >= rhs else {
    throw lhs.failure("\(value) is not more than or equal to \(rhs)")
  }
}

public func < <E: ExpectationType where E.ValueType: Comparable>(lhs: E, rhs: E.ValueType) throws {
  let value = try lhs.expression()
  guard value < rhs else {
    throw lhs.failure("\(value) is not less than \(rhs)")
  }
}

public func <= <E: ExpectationType where E.ValueType: Comparable>(lhs: E, rhs: E.ValueType) throws {
  let value = try lhs.expression()
  guard value <= rhs else {
    throw lhs.failure("\(value) is not less than or equal to \(rhs)")
  }
}
