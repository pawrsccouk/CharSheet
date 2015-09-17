//
//  XMLExtensions.swift
//  CharSheet-Swift
//
//  Created by Patrick Wallace on 30/06/2015.
//  Copyright (c) 2015 Patrick Wallace. All rights reserved.
//

import Foundation

extension DDXMLDocument {

	class func documentWithXMLString(string: String, options: UInt) -> Result<DDXMLDocument> {
		var error: NSError? = nil
		do {
			let doc = try DDXMLDocument(XMLString: string, options: options)
			return success(doc)
		} catch let error1 as NSError {
			error = error1
		}
		return failure(error!)
	}

	class func documentWithData(data: NSData, options: UInt) -> Result<DDXMLDocument> {
		var error: NSError? = nil
		do {
			let doc = try DDXMLDocument(data: data, options: options)
			return success(doc)
		} catch let error1 as NSError {
			error = error1
		}
		return failure(error!)
	}

	func xmlDataWithOptions(options: UInt) -> Result<NSData> {
		let data = self.XMLDataWithOptions(options)
		if data != nil {
			return success(data)
		}
		return failure(XMLSupport.XMLError("XMLDataWithOptions failed with no error message"))
	}
}
