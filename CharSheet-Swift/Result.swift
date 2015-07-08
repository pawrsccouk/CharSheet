//
//  Result.swift
//  CharSheet-Swift
//
//  Created by Patrick Wallace on 30/06/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

import Foundation

class Box<T>
{
	var unwrap: T
	init(value: T) {
		self.unwrap = value
	}
}

enum Result<T>
{
	case Success(value: Box<T>)
	case Error(error: NSError)

	var error: NSError? {
		switch self {
		case .Success:
			return nil
		case .Error(let error):
			return error
		}
	}

	var success: Bool {
		switch self {
		case .Success:
			return true
		case .Error:
			return false
		}
	}

	func andThen<U>(fn: (T) -> Result<U> ) -> Result<U> {
		switch self {
		case .Success(let value):
			return fn(value.unwrap)
		case .Error(let error):
			return Result<U>.Error(error: error)
		}
	}

	/// Convert a Result with a type to the typeless success-or-failure of NilResult.
	func nilResult() -> NilResult {
		switch self {
		case .Success: return NilResult.Success(value: Box(value:()))
		case .Error(let error): return NilResult.Error(error: error)
		}
	}
}

typealias NilResult = Result<()>

func success<T>(value: T) -> Result<T>
{
	return Result.Success(value: Box(value: value))
}

func success() -> NilResult
{
	return Result.Success(value: Box(value:()))
}

func failure<T>(error: NSError) -> Result<T>
{
	return Result.Error(error: error)
}
